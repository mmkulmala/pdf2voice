
# PDF to Audiobook (MP3)

This is a simple command-line tool to convert PDF files into MP3 audiobooks using Google Text-to-Speech (gTTS).

## Features
- Extracts text from PDF files
- Automatically detects language (or you can specify)
- Splits text into chunks for TTS processing
- Merges audio chunks into a single MP3 file
- Progress bars for conversion and merging
- Language detection based on PDF and ability to change language

## Requirements
- Python 3.7+
- [PyPDF2](https://pypi.org/project/PyPDF2/)
- [gtts](https://pypi.org/project/gTTS/)
- [pydub](https://pypi.org/project/pydub/)
- [langdetect](https://pypi.org/project/langdetect/)
- [tqdm](https://pypi.org/project/tqdm/)
- [ffmpeg](https://ffmpeg.org/) (for audio merging)

Install dependencies:
```sh
pip install -r requirements.txt
brew install ffmpeg
```

## Usage

```sh
python pdf_to_audiobook.py input.pdf output.mp3
```

Optional arguments:
- `--chunk-size N` : Set text chunk size for TTS (default: 4000)
- `--language LANG` : Force specific language (e.g., 'en', 'es', 'fr')

Example of forcing language:
```sh
python pdf_to_audiobook.py mybook.pdf mybook.mp3 --chunk-size 3000 --language en
```

Example with language detection:
```sh
python pdf_to_audiobook.py mybook.pdf mybook.mp3 --chunk-size 3000
```

## Notes
- Output MP3 will be saved to the path you specify.
- If no language is specified, it will be auto-detected from the PDF text.
- Make sure `ffmpeg` is installed and available in your PATH.
- there are two version that do the same for testing purposes and trying out performance of Mojo
