import os, docker, datetime, subprocess, time
from mcrcon import MCRcon
from pathlib import Path

def fisrt_run_minecraft_commands(mcrcon_host):
    mcrcon_host.connect()
    mcrcon_host.command("setworldspawn 0 ~ 0")
    mcrcon_host.command("defaultgamemode survival")
    mcrcon_host.command("time set 0")
    mcrcon_host.command("weather clear")
    mcrcon_host.command("difficulty normal")
    mcrcon_host.command("gamerule keepInventory false")
    mcrcon_host.command("gamerule doMobSpawning true")
    mcrcon_host.command("gamemode @a survival")
    mcrcon_host.command("say Servidor configurado com sucesso")
    time.sleep(2)
    mcrcon_host.command("say Aproveite a jogatina ;D")
    mcrcon_host.disconnect()

def do_backup(mcrcon_host):

    mcrcon_host.connect()

    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_name = f"server_backup_{timestamp}"

    world_path = Path("/minecraft/server-world")
    backup_path = Path("/app/backups") 
    
    backup_file = backup_path / f"{backup_name}.tar.gz"
    
    backup_path.mkdir(exist_ok=True)
    print(f"Creating backup: {backup_name}")
    mcrcon_host.command("say Starting backup now.")

    try:

        mcrcon_host.command("save-off")
        mcrcon_host.command("save-all")
        time.sleep(5)  
        
        subprocess.run([
            'tar', 
            '--create', 
            '--gzip', 
            '--file', str(backup_file),
            '--directory', str(world_path.parent),
            world_path.name
        ], check=True)

        mcrcon_host.command("save-on")
        mcrcon_host.command("say Backup completed successfully.")

        mcrcon_host.disconnect()

        print(f"Backup {backup_name} created successfully at {backup_file}")
        print (f"Size: {os.path.getsize(backup_file)} bytes")

    except subprocess.CalledProcessError as e:
        mcrcon_host.command("save-on")
        mcrcon_host.command("say Backup failed!")
        print(f"Backup {backup_name} failed: {e}")
        
        mcrcon_host.disconnect()

        if backup_file.exists():
            backup_file.unlink()

    except Exception as e:
        mcrcon_host.command("save-on")
        mcrcon_host.command("say Backup failed due to an unexpected error!")
        print(f"Backup {backup_name} failed due to an unexpected error: {e}")
        
        mcrcon_host.disconnect()

        if backup_file.exists():
            backup_file.unlink()

def list_backups():
    backup_path = Path("/app/backups")
    
    if not backup_path.exists():
        return []
    
    backups = sorted(backup_path.glob("server_backup_*.tar.gz"), key=os.path.getmtime, reverse=True)
    return backups
    
def cleanup_old_backups(keep_count=5):

    backups = list_backups()
    
    if len(backups) > keep_count:
        to_delete = backups[keep_count:]

        for backup_zip in to_delete:
    
            try:
                os.remove(backup_zip)
                print(f"Deleted old backup: {backup_zip.name}")
    
            except Exception as e:
                print(f"Failed to delete backup {backup_zip.name}: {e}")
     
if __name__ == "__main__":
    
    environment_interval = int(os.getenv("BACKUP_INTERVAL", "3600"))
    environment_keep = int(os.getenv("KEEP_BACKUPS", "5"))
    mcrcon_host = MCRcon(host="minecraft-server", password="mgmm4103", port=25575)

    while True:
        
        do_backup(mcrcon_host=mcrcon_host)
        cleanup_old_backups(keep_count=environment_keep)

        backups = list_backups()
        print(f"Total backups retained: {len(backups)}")

        for b in backups:
            print(f" - {b.name} (Size: {os.path.getsize(b)} bytes)")

        print(f"Next backup in {environment_interval} seconds.")
        time.sleep(environment_interval)