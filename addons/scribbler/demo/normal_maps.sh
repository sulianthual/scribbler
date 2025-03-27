 #!/bin/bash
# /home/sul/Documents/Apps/Laigter-x86_64.AppImage --no-gui -d pirate.png -n

for file in *.png; do
  /home/sul/Documents/Apps/Laigter-x86_64.AppImage --no-gui -d "$file" -n
  echo "$file" 
done
