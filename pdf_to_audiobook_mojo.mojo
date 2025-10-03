# pdf_to_audiobook_mojo.mojo
# Mojo version for faster chunk processing (TTS generation)
# This is a template; actual TTS and PDF libraries may differ in Mojo

from python import Python

fn extract_text_from_pdf(pdf_path: String) raises -> String:
    let PyPDF2 = Python.import_module("PyPDF2")
    let builtins = Python.import_module("builtins")
    
    let file = builtins.open(pdf_path, "rb")
    let pdf_reader = PyPDF2.PdfReader(file)
    var full_text = String("")
    let pages = pdf_reader.pages
    let num_pages = builtins.len(pages)
    
    for page_num in range(num_pages):
        let page = pages[page_num]
        let text = page.extract_text()
        let text_str = String(text)
        if text_str.strip():
            full_text += "\nPage " + String(page_num + 1) + "\n" + text_str + "\n"
    
    _ = file.close()
    return full_text.strip()

fn detect_language(text: String, default: String = "en") raises -> String:
    let langdetect = Python.import_module("langdetect")
    let sample_text = text[:5000] if len(text) > 0 else String("Hello")
    try:
        let detected = langdetect.detect(sample_text)
        return String(detected)
    except:
        return default

fn split_into_chunks(text: String, chunk_size: Int = 4000) raises -> PythonObject:
    let builtins = Python.import_module("builtins")
    let chunks = builtins.list()
    var start = 0
    let text_len = len(text)
    
    while start < text_len:
        var end = start + chunk_size
        if end >= text_len:
            _ = chunks.append(text[start:])
            break
        
        let break_chars = builtins.list()
        _ = break_chars.append(".")
        _ = break_chars.append("!")
        _ = break_chars.append("?")
        _ = break_chars.append("\n\n")
        
        for i in range(4):
            let break_char = break_chars[i]
            let text_py = PythonObject(text)
            let break_pos = text_py.rfind(break_char, start, end)
            if break_pos != -1:
                end = break_pos.__index__() + 1
                break
        
        _ = chunks.append(text[start:end])
        start = end
    return chunks

fn process_chunks_mojo(chunks: PythonObject, lang: String, temp_dir: String) raises -> PythonObject:
    let gtts = Python.import_module("gtts")
    let os = Python.import_module("os")
    let builtins = Python.import_module("builtins")
    
    let temp_files = builtins.list()
    let num_chunks = builtins.len(chunks)
    
    for idx in range(num_chunks):
        try:
            let chunk = chunks[idx]
            let tts = gtts.gTTS(chunk, lang)
            let filename = os.path.join(temp_dir, "part_" + String(idx) + ".mp3")
            _ = tts.save(filename)
            _ = temp_files.append(filename)
        except e:
            print("Error processing chunk", idx, ":", e)
    return temp_files

# Main entry point for Mojo version
fn main() raises:
    let sys = Python.import_module("sys")
    let tempfile = Python.import_module("tempfile")
    let builtins = Python.import_module("builtins")
    let pydub = Python.import_module("pydub")
    
    let argv = sys.argv
    let argc = builtins.len(argv).__index__()
    
    if argc < 3:
        print("Usage: pdf_to_audiobook_mojo.mojo input.pdf output.mp3 [--chunk-size N] [--language LANG]")
        return

    let input_pdf = String(argv[1])
    let output_mp3 = String(argv[2])
    var chunk_size = 4000
    var lang = String("")
    var lang_specified = False

    # Parse optional args
    var i = 3
    while i < argc:
        let arg = String(argv[i])
        if arg == "--chunk-size" and i + 1 < argc:
            chunk_size = atol(String(argv[i + 1]))
            i += 2
        elif arg == "--language" and i + 1 < argc:
            lang = String(argv[i + 1])
            lang_specified = True
            i += 2
        else:
            i += 1

    # Extract text
    print("Reading PDF...")
    let full_text = extract_text_from_pdf(input_pdf)
    if len(full_text) == 0:
        print("No text found in PDF")
        return

    print("Extracted", len(full_text), "characters")

    # Detect language
    if not lang_specified:
        lang = detect_language(full_text)
    print("Using language:", lang)

    # Split into chunks
    let chunks = split_into_chunks(full_text, chunk_size)
    let num_chunks = builtins.len(chunks).__index__()
    print("Processing", num_chunks, "chunks...")

    # Generate MP3 chunks
    let temp_dir_obj = tempfile.TemporaryDirectory()
    let temp_dir = String(temp_dir_obj.name)
    
    let temp_files = process_chunks_mojo(chunks, lang, temp_dir)
    if builtins.len(temp_files).__index__() == 0:
        print("No audio files generated")
        _ = temp_dir_obj.cleanup()
        return

    # Merge audio files
    print("Merging audio files...")
    let AudioSegment = pydub.AudioSegment
    var final_audio = PythonObject()
    var first = True
    
    for i in range(builtins.len(temp_files).__index__()):
        let filename = temp_files[i]
        let audio_chunk = AudioSegment.from_mp3(filename)
        if first:
            final_audio = audio_chunk
            first = False
        else:
            final_audio = final_audio + audio_chunk

    # Export final file
    print("Saving final audio file...")
    # Store final_audio in a temp variable for Python to access
    let py_builtins = Python.import_module("builtins")
    var globals_dict = py_builtins.dict()
    _ = globals_dict.__setitem__("final_audio", final_audio)
    _ = globals_dict.__setitem__("output_mp3", output_mp3)
    _ = py_builtins.eval("final_audio.export(output_mp3, format='mp3', bitrate='128k')", globals_dict)
    _ = temp_dir_obj.cleanup()
    print("Success! Audiobook saved as", output_mp3)
