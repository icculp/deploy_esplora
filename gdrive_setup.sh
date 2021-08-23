#!/usr/bin/env bash
wget -O gdrive https://docs.google.com/uc?id=0B3X9GlR6EmbnWksyTEtCM0VfaFE&export=download
chmod +x gdrive
sudo install gdrive /usr/local/bin/gdrive
gdrive list
# paste output on screen to a browser where your google account is logged in, and give access to project
