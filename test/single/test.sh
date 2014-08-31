cd test

vagrant up

echo "/etc/hosts file:"
vagrant ssh -c 'cat /etc/hosts'

vagrant destroy -f

cd ..