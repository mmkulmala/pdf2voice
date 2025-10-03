import argparse
import os
import PyPDF2
from gtts import gTTS
from pydub import AudioSegment
from langdetect import detect
from tqdm import tqdm
import tempfile

def extract_text_from_pdf(pdf_path):
    """Extract text from PDF with error handling"""
    try:
        with open(pdf_path, "rb") as file:
            pdf_reader = PyPDF2.PdfReader(file)
            full_text = ""
            
            for page_num in range(len(pdf_reader.pages)):
                text = pdf_reader.pages[page_num].extract_text()
                if text.strip():
                    full_text += f"\nPage {page_num + 1}\n{text}\n"
            
            return full_text.strip()
    except Exception as e:
        raise Exception(f"Error reading PDF: {e}")

def detect_language(text, default="en"):
    """Detect language with fallback"""
    sample_text = text[:5000] or "Hello"
    try:
        return detect(sample_text)
    except Exception:
        return default

def split_into_chunks(text, chunk_size=4000):
    """Split text into chunks, trying to break at sentence boundaries"""
    chunks = []
    start = 0
    
    while start < len(text):
        end = start + chunk_size
        
        if end >= len(text):
            chunks.append(text[start:])
            break
            
        # Try to break at a sentence end
        break_chars = ['.', '!', '?', '\n\n']
        for break_char in break_chars:
            break_pos = text.rfind(break_char, start, end)
            if break_pos != -1:
                end = break_pos + 1
                break
        
        chunks.append(text[start:end])
        start = end
    
    return chunks

def main():
    # --- CLI ARGUMENTS ---
    parser = argparse.ArgumentParser(description="Convert PDF to Audiobook (MP3)")
    parser.add_argument("input_pdf", help="Path to the input PDF file")
    parser.add_argument("output_mp3", help="Path to the output MP3 file")
    parser.add_argument("--chunk-size", type=int, default=4000, 
                       help="Text chunk size for processing (default: 4000)")
    parser.add_argument("--language", default=None,
                       help="Force specific language (e.g., 'en', 'es', 'fr')")
    
    args = parser.parse_args()

    # Validation
    if not os.path.exists(args.input_pdf):
        print(f"❌ Error: Input file '{args.input_pdf}' not found")
        return

    # Create output directory if needed
    output_dir = os.path.dirname(os.path.abspath(args.output_mp3))
    if output_dir:  # Only create if path contains a directory
        os.makedirs(output_dir, exist_ok=True)

    try:
        # --- READ PDF ---
        print("📖 Reading PDF...")
        full_text = extract_text_from_pdf(args.input_pdf)
        
        if not full_text:
            print("❌ No text found in PDF")
            return

        print(f"📄 Extracted {len(full_text)} characters")

        # --- DETECT LANGUAGE ---
        lang = args.language or detect_language(full_text)
        print(f"🌍 Using language: {lang}")

        # --- SPLIT INTO CHUNKS ---
        chunks = split_into_chunks(full_text, args.chunk_size)
        print(f"📝 Processing {len(chunks)} chunks...")

        # --- GENERATE MP3 CHUNKS ---
        temp_files = []
        print("🎙️ Generating audio...")
        
        with tempfile.TemporaryDirectory() as temp_dir:
            for idx, chunk in enumerate(tqdm(chunks, desc="Converting", unit="chunk")):
                try:
                    tts = gTTS(text=chunk, lang=lang)
                    filename = os.path.join(temp_dir, f"part_{idx}.mp3")
                    tts.save(filename)
                    temp_files.append(filename)
                except Exception as e:
                    print(f"⚠️ Error processing chunk {idx}: {e}")
                    continue

            # --- MERGE AUDIO FILES ---
            if not temp_files:
                print("❌ No audio files generated")
                return

            print("🔗 Merging audio files...")
            final_audio = AudioSegment.empty()
            
            for filename in tqdm(temp_files, desc="Merging", unit="file"):
                try:
                    audio_chunk = AudioSegment.from_mp3(filename)
                    final_audio += audio_chunk
                except Exception as e:
                    print(f"⚠️ Error merging {filename}: {e}")
                    continue

            # --- EXPORT FINAL FILE ---
            print("💾 Saving final audio file...")
            final_audio.export(args.output_mp3, format="mp3", bitrate="128k")
            
        print(f"✅ Success! Audiobook saved as {args.output_mp3}")
        print(f"📊 Final audio length: {len(final_audio) / 1000 / 60:.2f} minutes")

    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()