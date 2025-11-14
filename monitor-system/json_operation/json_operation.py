import json, docker, os


class JsonOperation:

    @staticmethod
    def load_json(file_path):
        """Carrega dados JSON de um arquivo"""
        if not os.path.exists(file_path):
            return None
        try:
            with open(file_path, 'r') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading JSON from {file_path}: {e}")
            return None

    @staticmethod
    def save_json(file_path, data):
        """Salva dados JSON em um arquivo"""
        try:
            os.makedirs(os.path.dirname(file_path), exist_ok=True)
            with open(file_path, 'w') as f:
                json.dump(data, f, indent=2)
            print(f"JSON saved to {file_path}")
        except Exception as e:
            print(f"Error saving JSON to {file_path}: {e}")