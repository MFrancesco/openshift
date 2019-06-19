if [ -z "$1" ]; then
	echo "No cluster name supplied, ./generate_keystore.sh <Name of kafka cluster>"
	exit 1
fi
echo "Will extract ${1}-cluster-ca-cert"
rm -f ca.crt
rm -f truststore.jks
oc extract secret/${1}-cluster-ca-cert --keys=ca.crt --to=- > ca.crt
keytool -import -trustcacerts -alias root -file ca.crt -keystore truststore.jks -storepass password -noprompt
