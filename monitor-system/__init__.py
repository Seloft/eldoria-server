"""
Minecraft Server Monitor
Monitora e gerencia mods automaticamente
"""

__version__ = "1.0.0"
__author__ = "GitHub Copilot Assistant"

from .files_operation.files_operation import FilesOperation
from .json_operation.json_operation import JsonOperation  
from .mods_operation.mods_operation import ModsManager

__all__ = [
    'FilesOperation',
    'JsonOperation', 
    'ModsManager'
]