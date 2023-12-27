const express = require('express');
const { Gateway, Wallets } = require('fabric-network');
const path = require('path');
const fs = require('fs');
const FabricCAServices = require('fabric-ca-client');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

app.use(bodyParser.json());

async function enrollUser() {
    const caURL = 'https://localhost:7054'; // Replace with your Fabric CA URL
    const ca = new FabricCAServices(caURL);
  
    const walletPath = path.join(__dirname, 'wallet');
    const wallet = await Wallets.newFileSystemWallet(walletPath);
  
    const userIdentity = await wallet.get('user1');
    if (userIdentity) {
      console.log('An identity for the user "user1" already exists in the wallet');
      return;
    }
  
    const enrollment = await ca.enroll({ enrollmentID: 'user1', enrollmentSecret: 'user1pw' });
    const x509Identity = {
      credentials: {
        certificate: enrollment.certificate,
        privateKey: enrollment.key.toBytes(),
      },
      mspId: 'DynoMSP', // Replace with your MSP ID
      type: 'X.509',
    };
  
    await wallet.put('user1', x509Identity);
    console.log('Successfully enrolled and imported identity into the wallet');
}

// Connect to Fabric network
async function connectToNetwork() {
  const gateway = new Gateway();
  const walletPath = path.join(__dirname, 'wallet');
  const wallet = await Wallets.newFileSystemWallet(walletPath);
  const ccpPath = path.resolve(__dirname, 'connection.json');
  let connectionProfile = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

  await enrollUser();
  
  await gateway.connect(connectionProfile, {
    wallet,
    identity: 'user1',
    discovery: { enabled: true, asLocalhost: true }
  });

  return gateway.getNetwork('mychannel');
}

// Endpoint to query all assets
app.get('/GetAllWallet', async (req, res) => {
    try {
      const network = await connectToNetwork();
      const contract = network.getContract('basic');
  
      const result = await contract.evaluateTransaction('GetAllAssets');
      res.send(result.toString());
    } catch (error) {
      res.status(500).send(error.message);
    }
});

// Endpoint to get wallet by Id 
app.get('/getWallet/:id', async (req, res) => {
  try {
      const id = req.params.id;
      console.log(id);
      const network = await connectToNetwork();
      const contract = network.getContract('basic');

      const result = await contract.evaluateTransaction('ReadAsset', id);
      res.send(result.toString());
  } catch (error) {
      res.status(500).send(error.message);
  }
});

// Endpoint to get a wallet by user Id
app.get('/getWalletByUserId/:assignToId', async (req, res) => {
  try {
      const assignToId = req.params.assignToId;
      console.log(assignToId);
      const network = await connectToNetwork();
      const contract = network.getContract('basic');

      const result = await contract.evaluateTransaction('GetWalletByUserId', assignToId);
      res.send(result.toString());
  } catch (error) {
      res.status(500).send(error.message);
  }
});

// Endpoint to create a new wallet
app.post('/createWallet', async (req, res) => {
  
  const { id, privateKey, publicKey, walletType, assignToId, assignToType, status } = req.body;

  try {
    const network = await connectToNetwork();
    const contract = network.getContract('basic');
    const balance = 0;

    const result = await contract.submitTransaction(
      'CreateAsset',
      id,
      privateKey, 
      publicKey, 
      balance,
      walletType, 
      assignToId, 
      assignToType, 
      status
    );

    console.log(result);
    res.send(result.toString());
  } catch (error) {
    res.status(500).send(error.message);
  }
});

// Endpoint to create a new 4 wallets for users 
app.post('/createDefaultWallets', async (req, res) => {
  
  const wallets = req.body;
  console.log(wallets);
  try {
    const network = await connectToNetwork();
    const contract = network.getContract('basic');
    const balance = 0;

    wallets.forEach(async (wallet) => {
      const { id, privateKey, publicKey, walletType, assignToId, assignToType, status } = wallet;
      
      const result = await contract.submitTransaction(
        'CreateAsset',
        id,
        privateKey, 
        publicKey, 
        balance,
        walletType, 
        assignToId, 
        assignToType, 
        status
      );    
      console.log(result);     
    });

    res.status(200).send("Wallets created successfuly !");
    
  } catch (error) {
    res.status(500).send(error.message);
  }
});


// Endpoint to create a new wallet
app.put('/updateWallet', async (req, res) => {
  
  const { id, privateKey, publicKey, walletType, assignToId, assignToType, status } = req.body;

  try {
    const network = await connectToNetwork();
    const contract = network.getContract('basic');
    const balance = 0;

    const result = await contract.submitTransaction(
      'UpdateAsset',
      id,
      privateKey, 
      publicKey, 
      balance,
      walletType, 
      assignToId, 
      assignToType, 
      status
    );

    console.log(result);

    res.send(result.toString());
  } catch (error) {
    res.status(500).send(error.message);
  }
});

// Endpoint to create a new wallet
app.post('/Transaction', async (req, res) => {
  
  const { senderPrivateKey, receiverPublicKey, amount } = req.body;

  try {
    const network = await connectToNetwork();
    const contract = network.getContract('basic');

    const result = await contract.submitTransaction(
      'Transaction',
      senderPrivateKey,
      receiverPublicKey,
      amount
    );

    console.log(result);

    res.send(result.toString());
  } catch (error) {
    res.status(500).send(error.message);
  }
});




app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});