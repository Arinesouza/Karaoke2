import os
import csv
import re
import torch
from ytmusicapi import YTMusic

# === MODELOS DE IA ===
from sentence_transformers import SentenceTransformer, util
import whisper


# ======================================================
#      FUNÇÃO QUE O servidor.py ESPERA
# ======================================================
def configurar_ffmpeg_local():
    """
    Procura o ffmpeg.exe na pasta ./ffmpeg e adiciona ao PATH local.
    """
    base_dir = os.path.dirname(__file__)
    ffmpeg_path = os.path.join(base_dir, "ffmpeg", "ffmpeg.exe")

    if os.path.exists(ffmpeg_path):
        os.environ["PATH"] += os.pathsep + os.path.dirname(ffmpeg_path)
        print("[OK] FFmpeg configurado localmente.")
    else:
        print("[ERRO] ffmpeg.exe não encontrado na pasta ./ffmpeg/")
        print("Coloque o arquivo em: backend_python/ffmpeg/ffmpeg.exe")


# ---------------------------
#        CONFIGURAÇÕES
# ---------------------------
ARQUIVO_CSV_GLOBAL = "musicas.csv"

# Carrega Whisper
print("[INFO] Carregando Whisper...")
whisper_model = whisper.load_model("base")

# Carrega SBERT
print("[INFO] Carregando SBERT...")
sbert = SentenceTransformer("all-MiniLM-L6-v2")


# ======================================================
#      FUNÇÕES ORIGINAIS DO script.py (AUDIO / IA)
# ======================================================

def transcrever_audio(caminho_audio):
    """
    Transcreve o áudio usando Whisper.
    """
    print(f"[TRANSCRIÇÃO] Processando: {caminho_audio}")
    result = whisper_model.transcribe(caminho_audio, fp16=False)
    return result["text"]


def avaliar_pronuncia(frase_referencia, frase_usuario):
    """
    Compara duas frases usando SBERT e retorna similaridade.
    """
    emb1 = sbert.encode(frase_referencia, convert_to_tensor=True)
    emb2 = sbert.encode(frase_usuario, convert_to_tensor=True)

    score = util.cos_sim(emb1, emb2).item()
    return round(score, 3)


def alinhar_palavras(letra_original, letra_cantada):
    """
    Início simples para alinhamento — depois podemos evoluir.
    """
    palavras_original = letra_original.split()
    palavras_usuario = letra_cantada.split()

    alinhamento = []

    for p in palavras_original:
        melhor = 0
        for u in palavras_usuario:
            sim = avaliar_pronuncia(p, u)
            melhor = max(melhor, sim)
        alinhamento.append((p, melhor))

    return alinhamento


# ======================================================
#    FUNÇÕES DE LETRAS (ANTES ERAM letras_csv.py)
# ======================================================

def buscar_letra_ytmusic(titulo, artista):
    """
    Busca a letra no YouTube Music usando ytmusicapi.
    Retorna a string da letra ou None se não encontrar.
    """
    yt = YTMusic()
    termo_busca = f"{titulo} {artista}"

    resultados = yt.search(termo_busca, filter="songs")

    if not resultados:
        return None

    video_id = resultados[0]['videoId']

    watch_playlist = yt.get_watch_playlist(videoId=video_id)
    lyrics_id = watch_playlist.get('lyrics')

    if not lyrics_id:
        return None

    lyrics_data = yt.get_lyrics(lyrics_id)
    return lyrics_data.get('lyrics', '')


def gerar_csv_palavras(titulo, artista, letra, arquivo_csv=ARQUIVO_CSV_GLOBAL):
    """
    Processa a letra e salva as palavras em CSV no modo append.
    """
    palavras = re.findall(r"\b\w+'\w+|\w+\b", letra)
    escrever_cabecalho = not os.path.exists(arquivo_csv)

    try:
        with open(arquivo_csv, "a", newline="", encoding="utf-8") as csvfile:
            writer = csv.writer(csvfile)

            if escrever_cabecalho:
                writer.writerow(["id", "titulo", "artista", "palavra"])

            for idx, palavra in enumerate(palavras, 1):
                writer.writerow([idx, titulo, artista, palavra])

        return True

    except Exception as e:
        print(f"[Erro CSV] Falha ao escrever CSV: {e}")
        return False


def buscar_e_adicionar_letra(titulo, artista, arquivo_csv=ARQUIVO_CSV_GLOBAL):
    """
    Função chamada pelo servidor.
    Busca a letra e adiciona ao CSV.
    """
    print(f"[LETRA BUSCA] Procurando letra: {titulo} - {artista}")

    letra = buscar_letra_ytmusic(titulo, artista)

    if not letra:
        print("[LETRA BUSCA] Não encontrada.")
        return False

    print("[LETRA BUSCA] Letra encontrada. Salvando no CSV...")
    return gerar_csv_palavras(titulo, artista, letra, arquivo_csv)

# ======================================================
#   COMPLEMENTO: FUNÇÕES EXIGIDAS PELO servidor.py
# ======================================================

def configurar_ffmpeg_local():
    """
    Verifica se existe ./ffmpeg/ffmpeg.exe
    """
    ffmpeg_path = os.path.join("ffmpeg", "ffmpeg.exe")
    if not os.path.exists(ffmpeg_path):
        print("[ERRO] ffmpeg.exe não encontrado na pasta ./ffmpeg/")
        print("Coloque o arquivo em: backend_python/ffmpeg/ffmpeg.exe")
        return False
    os.environ["FFMPEG_PATH"] = ffmpeg_path
    print("[FFMPEG] ffmpeg encontrado e configurado.")
    return True


def load_models():
    """
    Fornece exatamente o que servidor.py espera: (whisper_model, sbert)
    """
    print("[SCRIPT] Carregando modelos globalmente...")
    return whisper_model, sbert


# ======================================================
#   CSV: Funções usadas pelo servidor
# ======================================================

def carregar_csv_palavras(arquivo_csv):
    """
    Carrega o CSV e retorna lista de dicionários.
    """
    import pandas as pd
    if not os.path.exists(arquivo_csv):
        return None
    df = pd.read_csv(arquivo_csv)
    return df


def montar_letra_por_palavras(df, titulo):
    """
    Monta uma lista de palavras da letra com base no CSV.
    """
    df_musica = df[df["titulo"].str.lower() == titulo.lower()]
    if df_musica.empty:
        return None
    return df_musica["palavra"].tolist()


# ======================================================
#   IA: Alinhamento Inteligente / Comparações
# ======================================================

def transcrever_audio(modelo_whisper, caminho_audio):
    """
    Versão compatível com o servidor (modelo passado como parâmetro)
    """
    print(f"[TRANSCRIÇÃO] Processando: {caminho_audio}")
    result = modelo_whisper.transcribe(caminho_audio, fp16=False)
    return result["text"]


def alinhar_inteligente(modelo_sbert, palavras_original, palavras_usuario):
    """
    Faz alinhamento palavra a palavra com similaridade SBERT.
    Retorna:
        lista_original_alinhada,
        lista_usuario_alinhada
    """
    alinh_o = []
    alinh_u = []

    for p in palavras_original:
        melhor_score = -1
        melhor_u = ""

        for u in palavras_usuario:
            emb1 = modelo_sbert.encode(p, convert_to_tensor=True)
            emb2 = modelo_sbert.encode(u, convert_to_tensor=True)
            sim = util.cos_sim(emb1, emb2).item()

            if sim > melhor_score:
                melhor_score = sim
                melhor_u = u

        alinh_o.append(p)
        alinh_u.append(melhor_u)

    return alinh_o, alinh_u


def comparar_palavras(modelo_sbert, palavras_o, palavras_u):
    """
    Retorna:
        média de similaridade,
        lista de scores
    """
    scores = []
    for o, u in zip(palavras_o, palavras_u):
        emb1 = modelo_sbert.encode(o, convert_to_tensor=True)
        emb2 = modelo_sbert.encode(u, convert_to_tensor=True)
        s = util.cos_sim(emb1, emb2).item()
        scores.append(s)

    media = sum(scores) / len(scores) if scores else 0
    return media, scores


def calcular_nota(media):
    """
    Converte média (0 a 1) para nota de 0 a 99.
    """
    return int(media * 99)


def detectar_palavras_faltantes(lista_original, lista_usuario):
    """
    Identifica palavras da letra que não foram cantadas.
    """
    faltantes = []
    usuario_lower = [p.lower() for p in lista_usuario]

    for p in lista_original:
        if p.lower() not in usuario_lower:
            faltantes.append(p)

    cobertura = (1 - len(faltantes) / len(lista_original)) * 100
    return {
        "faltantes": faltantes,
        "cobertura": round(cobertura, 2)
    }

# ======================================================
#      TESTE LOCAL
# ======================================================

if __name__ == "__main__":
    print("--- Teste de Letra ---")
    t = input("Título: ")
    a = input("Artista: ")
    buscar_e_adicionar_letra(t, a)

    print("--- Teste de Áudio ---")
