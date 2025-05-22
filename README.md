# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js

git remote add origin https://github.com/alinakay02/escrow-app.git

запуск:
npx hardhat compile (из contracts)
npx hardhat node (contracts)

В другом терминале: 
npx hardhat run scripts/deploy.js --network localhost



# Деплой
npx hardhat run scripts/deploy.js --network teth

Далее в выводе будет 3 адрес, которые необходимо подставить в frontend/.env.local
```
