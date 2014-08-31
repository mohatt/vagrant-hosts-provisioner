cd test

vagrant up

echo "[mark] /etc/hosts file:"
vagrant ssh mark -c 'cat /etc/hosts'

echo "[john] /etc/hosts file:"
vagrant ssh john -c 'cat /etc/hosts'

echo "[brad] /etc/hosts file:"
vagrant ssh brad -c 'cat /etc/hosts'

vagrant destroy -f

cd ..