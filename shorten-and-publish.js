/**
 * shorten-and-publish.js
 * Pipeline completo pros 30 scripts já selecionados:
 *
 *   1. Pega o loadstring original (URL) de cada entrada do scripts-data.json
 *   2. Baixa o conteúdo real (o código Lua) dessa URL
 *   3. Sobe esse código como uma paste NOSSA no Pastefy (assim não depende
 *      mais do link de terceiro, que pode cair/ser removido)
 *   4. Pega o raw_url da paste nova
 *   5. Encurta esse raw_url no Shrtfly
 *   6. Salva tudo de volta no scripts-data.json (linkShrtfly, pastefyRaw)
 *
 * Já feito uma vez, uma entrada não é reprocessada (se já tem linkShrtfly,
 * pula) — então dá pra rodar de novo com segurança quando adicionar
 * scripts novos.
 *
 * Uso:
 *   npm install pastefy
 *   export PASTEFY_API_KEY="sua_chave"
 *   export SHRTFLY_API_KEY="sua_chave"
 *   node shorten-and-publish.js
 */

const fs = require("fs");
const path = require("path");
const Pastefy = require("pastefy");

const DATA_FILE = path.join(__dirname, "scripts-data.json");
const PASTEFY_API_KEY = process.env.PASTEFY_API_KEY;
const SHRTFLY_API_KEY = process.env.SHRTFLY_API_KEY;

if (!PASTEFY_API_KEY || !SHRTFLY_API_KEY) {
  console.error("Faltam as variáveis PASTEFY_API_KEY e/ou SHRTFLY_API_KEY. Exporte as duas antes de rodar.");
  process.exit(1);
}

const pastefy = new Pastefy(PASTEFY_API_KEY);

async function fetchLoadstringContent(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Não consegui baixar o conteúdo (status ${res.status})`);
  return res.text();
}

async function uploadToPastefy(title, content) {
  const result = await pastefy.paste.create(title, content, { visibility: "UNLISTED" });
  if (!result.success) throw new Error("Pastefy recusou a criação da paste");
  return result.paste.raw_url;
}

async function shortenWithShrtfly(longUrl) {
  const apiUrl = `https://shrtfly.com/api?api=${SHRTFLY_API_KEY}&url=${encodeURIComponent(longUrl)}&format=json`;
  const res = await fetch(apiUrl);
  const data = await res.json();
  // Convenção comum desse tipo de API: { status: "success", shortenedUrl: "..." }
  // Se o Shrtfly usar nomes diferentes, o log abaixo mostra a resposta crua
  // pra gente ajustar rapidinho.
  if (data.status !== "success" && !data.shortenedUrl) {
    console.log("Resposta crua do Shrtfly (ajustar parser se necessário):", JSON.stringify(data));
    throw new Error("Não consegui identificar o link encurtado na resposta do Shrtfly");
  }
  return data.shortenedUrl || data.short || data.url;
}

async function main() {
  const scripts = JSON.parse(fs.readFileSync(DATA_FILE, "utf-8"));
  let processed = 0;

  for (const script of scripts) {
    if (script.linkShrtfly) {
      console.log(`[pulado] ${script.jogo} — já tem link encurtado`);
      continue;
    }

    try {
      console.log(`\n[processando] ${script.jogo}`);

      const conteudo = await fetchLoadstringContent(script.loadstringOriginal);
      console.log(`  ✓ código baixado (${conteudo.length} caracteres)`);

      const rawUrl = await uploadToPastefy(script.jogo, conteudo);
      console.log(`  ✓ subido pro Pastefy: ${rawUrl}`);
      script.pastefyRaw = rawUrl;

      const shortUrl = await shortenWithShrtfly(rawUrl);
      console.log(`  ✓ encurtado: ${shortUrl}`);
      script.linkShrtfly = shortUrl;

      processed++;
    } catch (err) {
      console.log(`  ✗ erro em "${script.jogo}": ${err.message}`);
    }

    // pausa entre cada um, pra não tomar rate-limit de nenhuma das duas APIs
    await new Promise((r) => setTimeout(r, 800));
  }

  fs.writeFileSync(DATA_FILE, JSON.stringify(scripts, null, 2), "utf-8");
  console.log(`\nPronto: ${processed} scripts processados com sucesso de ${scripts.length}.`);
}

main();
