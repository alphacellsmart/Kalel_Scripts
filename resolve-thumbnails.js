/**
 * resolve-thumbnails.js
 * Resolve as thumbnails oficiais do Roblox pra cada script do scripts-data.json.
 *
 * Por que isso roda aqui (Node/servidor) e não direto no navegador:
 * as APIs do Roblox não liberam CORS pra sites de terceiros, então um
 * fetch() direto do downloads.html seria bloqueado pelo navegador.
 * Rodando por aqui (Termux, GitHub Actions, etc) não tem esse problema —
 * o resultado (uma URL de imagem normal) fica salvo no JSON, e a página
 * só usa um <img src="..."> comum, sem CORS nenhum.
 *
 * Uso:
 *   node resolve-thumbnails.js
 *
 * Lê e sobrescreve: scripts-data.json (adiciona o campo "thumbnail" em cada entrada)
 */

const fs = require("fs");
const path = require("path");

const DATA_FILE = path.join(__dirname, "scripts-data.json");

async function placeIdToUniverseId(placeId) {
  const res = await fetch(`https://apis.roblox.com/universes/v1/places/${placeId}/universe`);
  if (!res.ok) throw new Error(`Falha ao resolver universeId para placeId ${placeId} (status ${res.status})`);
  const data = await res.json();
  return data.universeId;
}

async function universeIdToThumbnail(universeId) {
  const url = `https://thumbnails.roblox.com/v1/games/icons?universeIds=${universeId}&size=512x512&format=Png&isCircular=false`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Falha ao buscar thumbnail para universeId ${universeId} (status ${res.status})`);
  const data = await res.json();
  const entry = data.data && data.data[0];
  return entry ? entry.imageUrl : null;
}

async function main() {
  const scripts = JSON.parse(fs.readFileSync(DATA_FILE, "utf-8"));
  let updated = 0;

  for (const script of scripts) {
    if (script.thumbnail) continue; // já resolvida, pula
    if (!script.placeId) {
      console.log(`[pulado] ${script.jogo} — sem PlaceId`);
      continue;
    }
    try {
      const universeId = await placeIdToUniverseId(script.placeId);
      const thumbUrl = await universeIdToThumbnail(universeId);
      if (thumbUrl) {
        script.thumbnail = thumbUrl;
        updated++;
        console.log(`[ok] ${script.jogo} -> ${thumbUrl}`);
      } else {
        console.log(`[sem imagem] ${script.jogo}`);
      }
    } catch (err) {
      console.log(`[erro] ${script.jogo}: ${err.message}`);
    }
    // pequena pausa pra não tomar rate-limit do Roblox
    await new Promise((r) => setTimeout(r, 300));
  }

  fs.writeFileSync(DATA_FILE, JSON.stringify(scripts, null, 2), "utf-8");
  console.log(`\nPronto: ${updated} thumbnails resolvidas de ${scripts.length} scripts.`);
}

main();
