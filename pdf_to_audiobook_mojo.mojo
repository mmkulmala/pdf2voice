# pdf_to_audiobook_mojo.mojo
# Mojo version for faster chunk processing (TTS generation)
# This is a template; actual TTS and PDF libraries may differ in Mojo

from python import PyPDF2, gtts, langdetect, tqdm
from python import tempfile, os

fn extract_text_from_pdf(pdf_path: str) -> str:
    with open(pdf_path, "rb") as file:
        pdf_reader = PyPDF2.PdfReader(file)
        full_text = ""
        for page_num in range(len(pdf_reader.pages)):
            text = pdf_reader.pages[page_num].extract_text()
            if text.strip():
                full_text += f"\nPage {page_num + 1}\n{text}\n"
        return full_text.strip()

fn detect_language(text: str, default: str = "en") -> str:
    sample_text = text[:5000] if text else "Hello"
    try:
        return langdetect.detect(sample_text)
    except Exception:
        return default

fn split_into_chunks(text: str, chunk_size: int = 4000) -> list[str]:
    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        if end >= len(text):
            chunks.append(text[start:])
            break
        break_chars = ['.', '!', '?', '\n\n']
        for break_char in break_chars:
            break_pos = text.rfind(break_char, start, end)
            if break_pos != -1:
                end = break_pos + 1
                break
        chunks.append(text[start:end])
        start = end
    return chunks

fn process_chunks_mojo(chunks: list[str], lang: str, temp_dir: str) -> list[str]:
    temp_files = []
    for idx, chunk in enumerate(chunks):
        try:
            tts = gtts.gTTS(text=chunk, lang=lang)
            filename = os.path.join(temp_dir, f"part_{idx}.mp3")
            tts.save(filename)
            temp_files.append(filename)
        except Exception as e:
            print(f"Error processing chunk {idx}: {e}")
            continue
    return temp_files

# Main entry point for Mojo version
fn main():
    import sys
    if len(sys.argv) < 3:
        print("Usage: pdf_to_audiobook_mojo.mojo input.pdf output.mp3 [--chunk-size N] [--language LANG]")
        return

    input_pdf = sys.argv[1]
    output_mp3 = sys.argv[2]
    chunk_size = 4000
    lang = None

    # Parse optional args
    i = 3
    while i < len(sys.argv):
        if sys.argv[i] == "--chunk-size" and i + 1 < len(sys.argv):
            chunk_size = int(sys.argv[i + 1])
            i += 2
        elif sys.argv[i] == "--language" and i + 1 < len(sys.argv):
            lang = sys.argv[i + 1]
            i += 2
        else:
            i += 1

    # Extract text
    print("Reading PDF...")
    full_text = extract_text_from_pdf(input_pdf)
    if not full_text:
        print("No text found in PDF")
        return

    print(f"Extracted {len(full_text)} characters")

    # Detect language
    if lang is None:
        lang = detect_language(full_text)
    print(f"Using language: {lang}")

    # Split into chunks
    chunks = split_into_chunks(full_text, chunk_size)
    print(f"Processing {len(chunks)} chunks...")

    # Generate MP3 chunks
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_files = process_chunks_mojo(chunks, lang, temp_dir)
        if not temp_files:
            print("No audio files generated")
            return

        # Merge audio files
        print("Merging audio files...")
        final_audio = None
        for filename in temp_files:
            audio_chunk = AudioSegment.from_mp3(filename)
            if final_audio is None:
                final_audio = audio_chunk
            else:
                final_audio += audio_chunk

        # Export final file
        print("Saving final audio file...")
        final_audio.export(output_mp3, format="mp3", bitrate="128k")
    print(f"Success! Audiobook saved as {output_mp3}")
