#!/usr/bin/bash

if [ x"$1" == "x" ]; then
    WRK_DIR=./
else
    WRK_DIR=$1
fi

cat > ${WRK_DIR}/ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "87600h"
      }
    }
  }
}
EOF

for nodes in nx-osv9000-1:172.16.30.101 nx-osv9000-2:172.16.30.102 nx-osv9000-3:172.16.30.103 nx-osv9000-4:172.16.30.104; do

INSTANCE=$(echo ${nodes} | cut -d: -f1)
IP=$(echo ${nodes} | cut -d: -f2)

cat > ${WRK_DIR}/${IP}-csr.json <<EOF
{
  "CN": "system:node:${IP}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "O": "system:nodes"
    }
  ]
}
EOF

sudo ${HOME}/bin/cfssl gencert \
  -ca=/etc/kubernetes/pki/ca.crt \
  -ca-key=/etc/kubernetes/pki/ca.key \
  -config=${WRK_DIR}/ca-config.json \
  -hostname=${IP} \
  -profile=kubernetes \
  ${WRK_DIR}/${IP}-csr.json | ${HOME}/bin/cfssljson -bare ${IP}

done
