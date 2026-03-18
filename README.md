# ytdl-manager 🎥

Gerenciador simples e leve para yt-dlp no macOS.

## Características

✅ Interface colorida e intuitiva no terminal  
✅ Detecta automaticamente o yt-dlp instalado  
✅ Configura pasta de downloads (salva como padrão)  
✅ Baixa vídeos até 1080p sem áudio  
✅ Mostra progresso em tempo real  
✅ Verifica versão e atualizações do yt-dlp  

## Pré-requisitos

Você precisa ter o yt-dlp instalado. Se ainda não tem:

```bash
# Usando Homebrew (recomendado)
brew install yt-dlp

# OU usando pip
pip3 install yt-dlp
```

## Instalação

1. Baixe os arquivos `ytdl-manager.sh` e `install.sh`

2. No terminal, navegue até a pasta dos arquivos e execute:

```bash
chmod +x install.sh
./install.sh
```

3. Se solicitado, adicione o PATH ao seu shell (o instalador pode fazer isso automaticamente)

4. Recarregue seu shell:

```bash
source ~/.zshrc  # se usa zsh (padrão no macOS)
# ou
source ~/.bash_profile  # se usa bash
```

## Como usar

Simplesmente digite no terminal:

```bash
ytdl
```

### Menu Principal

**1 - Baixar vídeo**
- Cole a URL do vídeo do YouTube (ou outro site suportado)
- O download começa automaticamente
- Vídeos são salvos na pasta configurada
- Após o download, você pode baixar outro ou voltar ao menu

**2 - Configurar pasta de downloads**
- Define onde os vídeos serão salvos
- A configuração é salva permanentemente
- Cria a pasta automaticamente se não existir

**3 - Verificar atualizações do yt-dlp**
- Verifica se há nova versão do yt-dlp
- Atualiza automaticamente se necessário

**4 - Sair**
- Fecha o programa

## Configurações de Download

Os vídeos são baixados com as seguintes especificações:

- **Qualidade máxima**: 1080p
- **Áudio**: Removido (só vídeo)
- **Formato**: Melhor disponível
- **Nome do arquivo**: Mantém o título original do vídeo

## Arquivos de Configuração

As configurações são salvas em: `~/.ytdl-manager.conf`

Você pode editar manualmente se preferir:
```bash
nano ~/.ytdl-manager.conf
```

## Desinstalação

```bash
rm ~/.local/bin/ytdl
rm ~/.ytdl-manager.conf
```

E remova a linha do PATH do seu `~/.zshrc` ou `~/.bash_profile`

## Dicas

- Use `Ctrl+C` para cancelar um download
- URLs aceitas: YouTube, Vimeo, Twitter/X, Instagram, TikTok e centenas de outros sites
- Para baixar múltiplos vídeos rapidamente, use a opção 1 repetidamente

## Solução de Problemas

**yt-dlp não encontrado**
- Certifique-se que instalou com `brew install yt-dlp` ou `pip3 install yt-dlp`
- Verifique se o comando `yt-dlp --version` funciona no terminal

**Erro de permissão**
- Execute: `chmod +x ~/.local/bin/ytdl`

**Comando ytdl não encontrado após instalação**
- Certifique-se que executou `source ~/.zshrc`
- Verifique se `~/.local/bin` está no PATH: `echo $PATH`

## Suporte

Para mais informações sobre o yt-dlp, visite: https://github.com/yt-dlp/yt-dlp

---

Desenvolvido com ❤️ para facilitar seus downloads
