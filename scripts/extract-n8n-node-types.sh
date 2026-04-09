#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_FILE="${1:-$PROJECT_DIR/mcp-gateway/n8n_node_types.json}"
N8N_CONTAINER="${N8N_CONTAINER:-ai_n8n}"

echo "[extract-n8n-node-types] Extracting node definitions from $N8N_CONTAINER ..."

docker exec "$N8N_CONTAINER" node -e '
const fs   = require("fs");
const path = require("path");

function findFiles(dir, pattern, results, depth) {
  results = results || [];
  depth = depth || 0;
  if (depth > 6) return results;
  try {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory() && entry.name !== ".git" && entry.name !== "node_modules") {
        findFiles(full, pattern, results, depth + 1);
      } else if (entry.isFile() && pattern.test(entry.name)) {
        results.push(full);
      }
    }
  } catch (_) {}
  return results;
}

function mapProp(p) {
  return {
    displayName:    p.displayName,
    name:           p.name,
    type:           p.type,
    default:        p.default,
    required:       p.required || false,
    description:    p.description || "",
    options:        (p.options || []).map(o => ({
      name: o.name, value: o.value, description: o.description || ""
    })),
    displayOptions: p.displayOptions || {},
    placeholder:    p.placeholder || "",
  };
}

function extractDesc(desc, namePrefix) {
  const fullName = namePrefix ? namePrefix + "." + desc.name : desc.name;
  return {
    displayName: desc.displayName || desc.name,
    name:        fullName,
    description: desc.description || "",
    version:     desc.version,
    group:       desc.group || [],
    inputs:      desc.inputs || [],
    outputs:     desc.outputs || [],
    defaults:    desc.defaults || {},
    credentials: (desc.credentials || []).map(c => ({
      name: c.name, required: c.required || false, displayName: c.displayName || c.name
    })),
    properties:  (desc.properties || []).map(mapProp),
  };
}

const pkgRoots = [
  "/usr/local/lib/node_modules/n8n/node_modules/n8n-nodes-base/dist/nodes",
  "/usr/local/lib/node_modules/n8n/node_modules/@n8n/n8n-nodes-langchain/dist/nodes",
];

const nodes = [];
const seen = new Set();

for (const basePkg of pkgRoots) {
  if (!fs.existsSync(basePkg)) continue;
  const isLangchain = basePkg.includes("langchain");
  const prefix = isLangchain ? "@n8n/n8n-nodes-langchain" : "n8n-nodes-base";
  const files = findFiles(basePkg, /\.node\.js$/);

  for (const f of files) {
    try {
      const mod = require(f);
      for (const key of Object.keys(mod)) {
        const Cls = mod[key];
        if (typeof Cls !== "function") continue;
        let inst;
        try { inst = new Cls(); } catch(_) { continue; }

        if (inst.nodeVersions && typeof inst.nodeVersions === "object") {
          const versions = Object.keys(inst.nodeVersions).sort((a, b) => parseFloat(a) - parseFloat(b));
          const latestKey = versions[versions.length - 1];
          const latestCls = inst.nodeVersions[latestKey];
          let latestDesc;
          try {
            latestDesc = latestCls.description || (typeof latestCls === "function" ? new latestCls().description : null);
          } catch(_) {}
          if (latestDesc && latestDesc.name) {
            if (!seen.has(latestDesc.name)) {
              seen.add(latestDesc.name);
              const entry = extractDesc(latestDesc, prefix);
              entry.version = latestKey;
              entry.availableVersions = versions;
              nodes.push(entry);
            }
          }
          continue;
        }

        const desc = inst.description;
        if (!desc || !desc.name) continue;
        if (seen.has(desc.name)) continue;
        seen.add(desc.name);
        nodes.push(extractDesc(desc, prefix));
      }
    } catch (_) {}
  }
}

process.stdout.write(JSON.stringify(nodes, null, 0));
' > "$OUTPUT_FILE"

COUNT=$(python3 -c "import json; print(len(json.load(open('$OUTPUT_FILE'))))" 2>/dev/null || echo "?")
SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)

echo "[extract-n8n-node-types] Extracted $COUNT node types ($SIZE) → $OUTPUT_FILE"
