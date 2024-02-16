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

// Endpoint to query all wallets
app.get('/GetAllWallets', async (req, res) => {
    try {
      const network = await connectToNetwork();
      const contract = network.getContract('basic');
  
      const result = await contract.evaluateTransaction('GetAllWallets');
      var responseApi = 
      {
        "statusCode": 200,
        "objectValue": JSON.parse(result.toString())
      } 

      res.status(200).send(responseApi);
    } catch (error) {
      var responseApi = 
      {
        "statusCode": 500,
        "exceptionMessage": error.message
      }
      res.status(500).send(responseApi);
    }
});

// Endpoint to get wallet by Id 
app.get('/GetWallet/:id', async (req, res) => {
  try {
      const id = req.params.id;
      const network = await connectToNetwork();
      const contract = network.getContract('basic');

      const result = await contract.evaluateTransaction('GetWallet', id);
      var responseApi = 
      {
        "statusCode": 200,
        "objectValue": JSON.parse(result.toString())
      } 
      res.send(responseApi);
  } catch (error) {
    var responseApi = 
      {
        "statusCode": 500,
        "exceptionMessage": error.message
      }
      res.status(500).send(responseApi);
  }
});

// Endpoint to get a wallet by user Id
app.get('/getWalletsByUserId/:assignedToId', async (req, res) => {
  try {
      const assignToId = req.params.assignedToId;
      
      const network = await connectToNetwork();
      const contract = network.getContract('basic');
      const result = await contract.evaluateTransaction('GetWalletsByUserId', assignToId);
      var responseApi = 
      {
        "statusCode": 200,
        "objectValue": JSON.parse(result.toString())
      } 
      res.status(200).send(responseApi);
  } catch (error) {
    var responseApi = 
      {
        "statusCode": 500,
        "exceptionMessage": error.message
      }
      res.status(500).send(responseApi);
  }
});

// Endpoint to get a wallet by user Id and wallet Type
app.get('/GetUserWalletByType/:assignedToId/:walletType', async (req, res) => {
  try {
      const assignToId = req.params.assignedToId;
      const walletType = req.params.walletType;

      const network = await connectToNetwork();
      const contract = network.getContract('basic');

      const result = await contract.evaluateTransaction(
        'GetUserWalletByType', 
        assignToId,
        walletType
      );
      
      var responseApi = 
      {
        "statusCode": 200,
        "objectValue": JSON.parse(result.toString())
      }
      res.send(responseApi);
  } catch (error) {
    var responseApi = 
      {
        "statusCode": 500,
        "exceptionMessage": error.message
      }
      res.status(500).send(responseApi);
  }
});

// Endpoint to create a new wallet
app.post('/CreateWallet', async (req, res) => {
  
  const { Id, PrivateKey, PublicKey, WalletType, AssignedToType, AssignedToName, AssignedToId, Balance, Status } = req.body;

  try {
    const network = await connectToNetwork();
    const contract = network.getContract('basic');

    const result = await contract.submitTransaction(
      'CreateWallet',
      Id,
      PrivateKey, 
      PublicKey, 
      parseFloat(Balance),
      parseInt(WalletType), 
      AssignedToId, 
      AssignedToType, 
      parseInt(Status)
    );
    
    console.log(result.toString());
    var responseApi = 
    {
      "statusCode": 200,
      "objectValue": JSON.parse(result.toString())
    }

    res.status(200).send(responseApi);
  } catch (error) {

    var responseApi = 
    {
      "statusCode": 500,
      "objectValue": error.message
    }
    res.status(500).send(responseApi);
  }
});

// Endpoint to create a new 4 wallets for users 
app.post('/CreateDefaultWallets', async (req, res) => {
  
  const wallets = req.body;
  try {
    const network = await connectToNetwork();
    const contract = network.getContract('basic');

    wallets.forEach(async (wallet) => {
      try {
        const { Id, PrivateKey, PublicKey, WalletType, AssignedToType, AssignedToName, AssignedToId, Balance, Status } = wallet;
        console.log(wallet);
        const result = await contract.submitTransaction(
        'CreateWallet',
        Id,
        PrivateKey, 
        PublicKey, 
        Balance,
        WalletType, 
        AssignedToId, 
        AssignedToType, 
        Status
        ); 
      }catch (error) {

        var responseApi = 
        {
          "statusCode": 500,
          "objectValue": error.message
        }
        res.status(500).send(responseApi);
      }        
    });

    var responseApi = 
    {
      "statusCode": 200
    }
    
    res.status(200).send(responseApi);
  }catch (error) {

    var responseApi = 
    {
      "statusCode": 500,
      "objectValue": error.message
    }
    res.status(500).send(responseApi);
  }
});

// Endpoint to update The wallet
app.put('/updateWallet', async (req, res) => {
  
  const { id, privateKey, publicKey, balance, walletType, assignToId, assignToType, status } = req.body;

  try {
    const network = await connectToNetwork();
    const contract = network.getContract('basic');
    const result = await contract.submitTransaction(
      'UpdateWallet',
      id,
      privateKey, 
      publicKey, 
      balance,
      walletType, 
      assignToId, 
      assignToType, 
      status
    );

    var responseApi = 
    {
      "statusCode": 200,
      "objectValue": JSON.parse(result.toString())
    }

    res.status(200).send(responseApi);
  } catch (error) {
    var responseApi = 
    {
      "statusCode": 500,
      "objectValue": error.message
    }
    res.status(500).send(responseApi);
  }
});

// Endpoint to delete The wallet
app.delete('/deleteWallet/:id', async (req, res) => {
  
  try {
    const network = await connectToNetwork();
    const contract = network.getContract('basic');
    const id = req.params.id;

    const result = await contract.submitTransaction('DeleteWallet', id);

    var responseApi = 
    {
      "statusCode": 200,
      "objectValue": JSON.parse(result.toString())
    }

    res.status(200).send(responseApi);

  } catch (error) {
    var responseApi = 
    {
      "statusCode": 500,
      "objectValue": error.message
    }
    res.status(500).send(responseApi);
  }
});

// Endpoint to delete all wallets for user id
app.delete('/deleteWalletsbyUserId/:userId', async (req, res) => {
  
  try {
    const network = await connectToNetwork();
    const contract = network.getContract('basic');
    const userId = req.params.userId;

    const result = await contract.submitTransaction('deleteWalletsbyUserId', userId);

    var responseApi = 
    {
      "statusCode": 200,
      "objectValue": JSON.parse(result.toString())
    }

    res.status(200).send(responseApi);

  } catch (error) {
    var responseApi = 
    {
      "statusCode": 500,
      "objectValue": error.message
    }
    res.status(500).send(responseApi);
  }
});

// Endpoint to query all transactions
app.get('/GetAllTransactions', async (req, res) => {
  try {
    const network = await connectToNetwork();
    const contract = network.getContract('basic');

    const result = await contract.evaluateTransaction('GetAllTransactions');
    var responseApi = 
    {
      "statusCode": 200,
      "objectValue": JSON.parse(result.toString())
    } 

    res.status(200).send(responseApi);
  } catch (error) {
    var responseApi = 
    {
      "statusCode": 500,
      "objectValue": error.message
    }
    res.status(500).send(responseApi);
  }
});

// Endpoint to get transaction by Id 
app.get('/GetTransaction/:id', async (req, res) => {
  try {
      const id = req.params.id;
      const network = await connectToNetwork();
      const contract = network.getContract('basic');

      const result = await contract.evaluateTransaction('GetTransaction', id);
      var responseApi = 
      {
        "StatusCode": 200,
        "ObjectValue": JSON.parse(result.toString())
      } 
      res.send(responseApi);
  } catch (error) {
    var responseApi = 
    {
      "StatusCode": 500,
      "ExceptionMessage": error.message
    }
      res.status(500).send(responseApi);
  }
});

// Endpoint to get transaction by wallet Id 
app.get('/GetWalletTransactions/:walletId', async (req, res) => {
  try {
      const walletId = req.params.walletId;
      const network = await connectToNetwork();
      const contract = network.getContract('basic');

      const result = await contract.evaluateTransaction('GetWalletTransactions', walletId);
      var responseApi = 
      {
        "statusCode": 200,
        "objectValue": JSON.parse(result.toString())
      } 
      res.send(responseApi);
  } catch (error) {
    var responseApi = 
    {
      "statusCode": 500,
      "objectValue": error.message
    }
    res.status(500).send(responseApi);
  }
});

// Endpoint to get transaction by wallet Id where transaction equal to receiver
app.get('/GetWalletReceivedTransactions/:walletId', async (req, res) => {
  try {
      const walletId = req.params.walletId;
      const network = await connectToNetwork();
      const contract = network.getContract('basic');

      const result = await contract.evaluateTransaction('GetWalletReceivedTransactions', walletId);
      var responseApi = 
      {
        "statusCode": 200,
        "objectValue": JSON.parse(result.toString())
      } 
      res.send(responseApi);
  } catch (error) {
    var responseApi = 
    {
      "statusCode": 500,
      "objectValue": error.message
    }
    res.status(500).send(responseApi);
  }
});

// Endpoint to get transaction by wallet Id  where transaction equal to sender
app.get('/GetWalletSentTransactions/:walletId', async (req, res) => {
  try {
      const walletId = req.params.walletId;
      const network = await connectToNetwork();
      const contract = network.getContract('basic');

      const result = await contract.evaluateTransaction('GetWalletSentTransactions', walletId);
      var responseApi = 
      {
        "statusCode": 200,
        "objectValue": JSON.parse(result.toString())
      } 
      res.send(responseApi);
  } catch (error) {
    var responseApi = 
    {
      "statusCode": 500,
      "objectValue": error.message
    }
    res.status(500).send(responseApi);
  }
});

// Endpoint to get transaction by user Id 
app.get('/GetUserTransactions/:userId', async (req, res) => {
  try {
      const userId = req.params.userId;
      const network = await connectToNetwork();
      const contract = network.getContract('basic');

      const result = await contract.evaluateTransaction('GetUserTransactions', userId);
      var responseApi = 
      {
        "statusCode": 200,
        "objectValue": JSON.parse(result.toString())
      } 
      res.send(responseApi);
  } catch (error) {
    var responseApi = 
    {
      "statusCode": 500,
      "objectValue": error.message
    }
    res.status(500).send(responseApi);
  }
});

// Endpoint to get transaction by user Id where transaction is receiver 
app.get('/GetUserReceivedTransactions/:userId', async (req, res) => {
  try {
      const userId = req.params.userId;
      const network = await connectToNetwork();
      const contract = network.getContract('basic');

      const result = await contract.evaluateTransaction('GetUserReceivedTransactions', userId);
      var responseApi = 
      {
        "statusCode": 200,
        "objectValue": JSON.parse(result.toString())
      } 
      res.send(responseApi);
  } catch (error) {
    var responseApi = 
      {
        "statusCode": 500,
        "objectValue": error.message
      } 

      res.status(500).send(responseApi);
  }
});


// Endpoint to get transaction by user Id where transaction is receiver 
app.get('/GetUserSentTransactions/:userId', async (req, res) => {
  try {
      const userId = req.params.userId;
      const network = await connectToNetwork();
      const contract = network.getContract('basic');

      const result = await contract.evaluateTransaction('GetUserSentTransactions', userId);
      var responseApi = 
      {
        "StatusCode": 200,
        "ObjectValue": JSON.parse(result.toString())
      } 
      res.send(responseApi);
  } catch (error) {
    var responseApi = 
      {
        "StatusCode": 500,
        "ExceptionMessage": error.message
      } 

    res.status(500).send(responseApi);
  }
});

// Endpoint to create a new wallet
app.post('/CreateTransaction', async (req, res) => {
  
  const { id, senderWalletId, receiverWalletId, qrCodeId, amount, transactionDate, status } = req.body;

  try {
    const network = await connectToNetwork();
    const contract = network.getContract('basic');

    const result = await contract.submitTransaction(
      'CreateTransaction',
      id,
      senderWalletId,
      receiverWalletId, 
      qrCodeId,
      amount,
      transactionDate,
      status
    );
    
    var responseApi = 
      {
        "StatusCode": 200,
        "objectValue": JSON.parse(result.toString())
      } 

    res.send(responseApi);
  } catch (error) {
    var responseApi = 
    {
      "statusCode": 500,
      "objectValue": error.message
    }
    res.status(500).send(responseApi);
  }
});


// Endpoint to create a new wallet
app.post('/Transaction', async (req, res) => {
  
  const { Id, SenderPrivateKey, ReceiverPublicKey, Amount, QrCodeId, TransactionDate, Status } = req.body;

  try {
    const network = await connectToNetwork();
    const contract = network.getContract('basic');

    const result = await contract.submitTransaction(
      'Transaction',
      Id,
      SenderPrivateKey,
      ReceiverPublicKey,
      Amount, 
      QrCodeId,
      TransactionDate,
      Status
    );
    
    var responseApi = 
      {
        "StatusCode": 200,
        "ExceptionMessage": JSON.parse(result.toString())
      } 

    res.send(responseApi);
  } catch (error) {
    var responseApi = 
    {
      "statusCode": 500,
      "ExceptionMessage": error.message
    }
    res.status(500).send(responseApi);
  }
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});