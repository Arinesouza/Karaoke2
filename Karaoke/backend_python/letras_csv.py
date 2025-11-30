import csv

def carregar_letras(csv_path="musicas.csv"):
    letras = {}

    try:
        with open(csv_path, "r", encoding="utf-8") as f:
            reader = csv.reader(f)
            next(reader, None)  # pula header se existir

            for row in reader:
                if len(row) >= 2:
                    musica = row[0].strip()
                    letra = row[1].strip()
                    letras[musica] = letra

    except FileNotFoundError:
        print(f"[ERRO] Arquivo {csv_path} não encontrado!")

    return letras
