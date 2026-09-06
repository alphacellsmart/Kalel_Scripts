# Automação da Página de Downloads

Pipeline completo pros scripts do `scripts-data.json`: baixa o código, sobe no Pastefy (cópia sua, não depende do link de terceiro), encurta no Shrtfly, e atualiza o arquivo pronto pra página ler.

## Setup (Termux)

```bash
mkdir -p ~/downloads-page
cd ~/downloads-page
# copie pra cá: scripts-data.json, resolve-thumbnails.js, shorten-and-publish.js, package.json
npm install
```

## Configurar as chaves

```bash
export PASTEFY_API_KEY="sua_chave_do_pastefy"
export SHRTFLY_API_KEY="sua_chave_do_shrtfly"
```

## Rodar

**1. Resolver as thumbnails dos jogos (uma vez, ou quando adicionar jogo novo):**
```bash
npm run thumbnails
```

**2. Subir pro Pastefy e encurtar no Shrtfly:**
```bash
npm run publish
```

Isso processa só os scripts que **ainda não têm** `linkShrtfly` preenchido — então é seguro rodar de novo depois de adicionar scripts novos, sem duplicar trabalho nos que já foram feitos.

## Se o Shrtfly der erro

O parser de resposta do Shrtfly (`shortenWithShrtfly` em `shorten-and-publish.js`) assume o formato comum desse tipo de API (`{ status: "success", shortenedUrl: "..." }`). Se a resposta real do Shrtfly usar nomes diferentes de campo, o script imprime a resposta crua no terminal — me manda esse print que eu ajusto o parser na hora.

## Depois de rodar

O `scripts-data.json` fica atualizado com os links encurtados. Suba esse arquivo de volta pro GitHub (junto com o `downloads.html`, se também tiver mudado) — o Vercel publica sozinho.
