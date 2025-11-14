import os, hashlib, json, time
from datetime import datetime

class FilesOperation:
    def __init__(self, cache_file="/app/cache/mods-cache.json"):
        self.cache_file = cache_file
        self.cache_data = self.load_cache()

    def load_cache(self):
        if os.path.exists(self.cache_file):
            try:
                with open(self.cache_file, 'r') as f:
                    return json.load(f)
            except:
                return {}
        return {}

    def save_cache(self):
        os.makedirs(os.path.dirname(self.cache_file), exist_ok=True)
        with open(self.cache_file, 'w') as f:
            json.dump(self.cache_data, f, indent=2)

    def calculate_file_hash(self, file_path):
        if not os.path.exists(file_path):
            return None
        
        hash_md5 = hashlib.md5()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()

    def has_file_changed(self, file_path):
        current_hash = self.calculate_file_hash(file_path)
        cached_hash = self.cache_data.get(file_path, {}).get("hash")
        
        if current_hash != cached_hash:
            self.cache_data[file_path] = {
                "hash": current_hash,
                "last_check": datetime.now().isoformat()
            }
            self.save_cache()
            return True
        return False
    
    def check_file_exists(self, file_path):
        return os.path.isfile(file_path)