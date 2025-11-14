import time
import sys
import docker

from files_operation.files_operation import FilesOperation
from json_operation.json_operation import JsonOperation
from mods_operation.mods_operation import ModsManager

class MinecraftMonitor:
    def __init__(self, check_interval=60):
        self.check_interval = check_interval
        self.docker_client = None
        self.file_manager = None
        self.json_manager = None
        self.mods_manager = None
        
    def initialize(self):
        """Inicializa todas as dependências"""
        try:
            self.docker_client = docker.from_env()
            self.file_manager = FilesOperation()
            self.json_manager = JsonOperation()
            self.mods_manager = ModsManager(self.docker_client)
            return True
        
        except Exception as e:
            print(f"Failed to initialize: {e}")
            return False
    
    def run_check(self):
        """Executa uma verificação completa"""
        try:
            mods_file = "/app/mods-list.json"
            if not self.file_manager.check_file_exists(mods_file):
                print(f"Mods file not found: {mods_file}")
                return
            
            # Verificar se arquivo mudou
            if self.file_manager.has_file_changed(mods_file):
                print("Mods list changed! Processing updates...")
                
                # Ler lista de mods
                mods_list = self.json_manager.load_json(mods_file)
                if not mods_list:
                    print("Could not read mods list")
                    return
                
                print(f"Found {len(mods_list)} mods in list")
                
                # Processar mudanças
                changes_made = self.mods_manager.sync_mods(mods_list)
                
                if changes_made:
                    print("Changes detected, restarting Minecraft server...")
                    if self.mods_manager.restart_minecraft_server():
                        print("Server restarted successfully!")
                    else:
                        print("Failed to restart server!")
                
        except Exception as e:
            print(f"Error during check: {e}")
    
    def start_monitoring(self):
        """Inicia o loop de monitoramento"""
        if not self.initialize():
            return
        
        initial_await = 30
        time.sleep(initial_await)
        
        print(f"\nStarting monitor loop")
        print("Press Ctrl+C to stop\n")
        
        try:
            while True:
                self.run_check()
                time.sleep(self.check_interval)
                
        except KeyboardInterrupt:
            print("\nMonitor stopped by user")
        
        except Exception as e:
            print(f"Monitor error: {e}")


if __name__ == "__main__":

    print("Minecraft Monitor Starting...")
    interval = int(sys.argv[1]) if len(sys.argv) > 1 else 60
    monitor = MinecraftMonitor(interval)
    monitor.start_monitoring()

    