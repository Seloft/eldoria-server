import docker
import os

class ModsManager:
    def __init__(self, docker_client, container_name="minecraft-server"):
        self.docker_client = docker_client
        self.container_name = container_name
        self.mods_path = "/minecraft/mods/"
    
    def get_installed_mods(self):
        """Retorna lista de mods instalados"""
        try:
            container = self.docker_client.containers.get(self.container_name)
            result = container.exec_run(f"ls {self.mods_path}")
            
            if result.exit_code == 0:
                return result.output.decode().strip().splitlines()
            return []
        except Exception as e:
            print(f"Error getting installed mods: {e}")
            return []
    
    def download_mod(self, mod_info):
        """Baixa um mod específico"""
        try:
            container = self.docker_client.containers.get(self.container_name)
            
            url = mod_info.get("url-download")
            mod_name = mod_info.get('modname', 'Unknown')
            version = mod_info.get('version', 'Unknown')
            
            if not url:
                print(f"No download URL for {mod_name}")
                return False
            
            filename = f"{mod_name.replace(' ', '_')}-{version}.jar"
            command = f"wget --timeout=30 --tries=3 -q -O {self.mods_path}{filename} '{url}'"
            
            print(f"Downloading {mod_name} v{version}...")
            exit_code, output = container.exec_run(command)
            
            if exit_code == 0:
                print(f"Downloaded {mod_name}")
                return True
            else:
                print(f"Failed to download {mod_name}: {output.decode()}")
                return False
                
        except Exception as e:
            print(f"Error downloading mod: {e}")
            return False
    
    def remove_mod(self, mod_filename):
        """Remove um mod específico"""
        try:
            container = self.docker_client.containers.get(self.container_name)
            command = f"rm {self.mods_path}{mod_filename}"
            
            print(f"Removing {mod_filename}...")
            exit_code, output = container.exec_run(command)
            
            if exit_code == 0:
                print(f"Removed {mod_filename}")
                return True
            else:
                print(f"Failed to remove {mod_filename}: {output.decode()}")
                return False
                
        except Exception as e:
            print(f"Error removing mod: {e}")
            return False
    
    def sync_mods(self, target_mods_list):
        """Sincroniza mods com a lista desejada"""
        installed_mods = self.get_installed_mods()
        
        # Criar lista de mods esperados
        expected_mods = set()
        for mod in target_mods_list:
            filename = f"{mod.get('modname', '').replace(' ', '_')}-{mod.get('version', '')}.jar"
            expected_mods.add(filename)
        
        # Encontrar mods para baixar
        mods_to_download = []
        for mod in target_mods_list:
            filename = f"{mod.get('modname', '').replace(' ', '_')}-{mod.get('version', '')}.jar"
            if filename not in installed_mods:
                mods_to_download.append(mod)
        
        # Encontrar mods para remover
        mods_to_remove = []
        for installed_mod in installed_mods:
            if installed_mod.endswith('.jar') and installed_mod not in expected_mods:
                mods_to_remove.append(installed_mod)
        
        changes_made = False
        
        # Remover mods extras
        for mod_file in mods_to_remove:
            if self.remove_mod(mod_file):
                changes_made = True
        
        # Baixar mods necessários
        for mod_info in mods_to_download:
            if self.download_mod(mod_info):
                changes_made = True
        
        return changes_made
    
    def restart_minecraft_server(self):
        """Reinicia o servidor Minecraft"""
        try:
            container = self.docker_client.containers.get(self.container_name)
            print(f"Restarting {self.container_name}...")
            container.restart()
            return True
        except Exception as e:
            print(f"Failed to restart server: {e}")
            return False