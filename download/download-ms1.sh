#ms1 data download
mkdir -p ms1

ms1names=$(cut -d, -f1 params/sampleInfo.csv | tail -n +2)

#Loop through sample info file
for i in $ms1names
do 
echo "Downloading ms1 file $i"
curl -L https://www.ebi.ac.uk/metabolights/MTBLS233/files/${i} -o ms1/$i.tar.gz
tar -zxvf ms1/$i.tar.gz -C ms1/
done

# Wipe tar balls
rm -r ms1/*tar.gz