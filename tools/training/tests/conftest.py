"""conftest.py — fügt tools/training/ zum sys.path hinzu."""
import sys
from pathlib import Path

# tools/training/ muss im Suchpfad sein damit train_embedding importiert werden kann
sys.path.insert(0, str(Path(__file__).parent.parent))
