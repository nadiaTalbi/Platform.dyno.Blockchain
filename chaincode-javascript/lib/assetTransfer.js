/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

// Deterministic JSON.stringify()
const stringify  = require('json-stringify-deterministic');
const sortKeysRecursive  = require('sort-keys-recursive');
const { Contract } = require('fabric-contract-api');

class AssetTransfer extends Contract {

    async InitLedger(ctx) {
        const wallets = [
            {
                Id: '2144e667-6c8d-4d95-8132-21b1d735e969',
                PrivateKey: '@0000',
                PublicKey: '@0000',          
                Balance: 300,
                WalletType: 0,
                AssignToId: 'c23c03c2-a6f4-4423-842e-68b2c25711eb',
                AssignToType: 2,
                Status: 0
            },
            {
                Id: '2144e667-6c8d-4d95-8132-21b1d735a969',
                PrivateKey: '@0001',
                PublicKey: '@0001',          
                Balance: 200,
                WalletType: 0,
                AssignToId: 'cf346361-62d7-4c2e-bc3f-db9ab618e74a',
                AssignToType: 2,
                Status: 0
            },
            {
                Id: '9be3505b-0e15-4106-a56d-3cbfec1dc6b7',
                PrivateKey: '@0002',
                PublicKey: '@0002',          
                Balance: 500,
                WalletType: 0,
                AssignToId: '11476ad4-ffbd-4c98-ab9d-5a71a331249e',
                AssignToType: 2,
                Status: 0
            },
            {
                Id: 'f05944e8-f7ea-4c93-ad6c-09aa7dc07a07',
                PrivateKey: '@0003',
                PublicKey: '@0003',          
                Balance: 700,
                WalletType: 0,
                AssignToId: 'e4283ad2-fbe9-4185-a402-f38c1ba46d02',
                AssignToType: 2,
                Status: 0
            }
        ];

        const transactions= [
            {
                Id: "ac57bb49-6e51-4c15-8cc9-8022b1689c7d",
                SenderWalletId: "2144e667-6c8d-4d95-8132-21b1d735e969",
                ReceiverWalletId: "2144e667-6c8d-4d95-8132-21b1d735a969",
                QrCodeId: "bf45c9f1-f1ac-437e-b8d2-b3bfbfd803e3",
                Amount: 50,
                TransactionDate: new Date('1995-12-17T03:24:00'),
                Status: 0
            },
            {
                Id: "2f1cab86-957d-4b52-b13b-d1d8a2d6cea2",
                SenderWalletId: "2144e667-6c8d-4d95-8132-21b1d735e969",
                ReceiverWalletId: "2144e667-6c8d-4d95-8132-21b1d735a969",
                QrCodeId: "bf45c9f1-f1ac-437e-b8d2-b3bfbfd803e3",
                Amount: 60,
                TransactionDate: new Date('1995-12-16T03:24:00'),
                Status: 0
            }
        ]

        for (const wallet of wallets) {
            wallet.docType = 'Wallet';
            await ctx.stub.putState(wallet.Id, Buffer.from(stringify(sortKeysRecursive(wallet))));
        }

        for (const transaction of transactions) {
            transaction.docType = 'Transaction';
            await ctx.stub.putState(transaction.Id, Buffer.from(stringify(sortKeysRecursive(transaction))));
        }
    }

    // GetAllWallets returns all wallets found in the world state.
    async GetAllWallets(ctx) {
        const allResults = [];
        // range query with empty string for startKey and endKey does an open-ended query of all assets in the chaincode namespace.
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();
        while (!result.done) {
            const strValue = Buffer.from(result.value.value.toString()).toString('utf8');
            let record;
            try {
                record = JSON.parse(strValue);
            } catch (err) {
                console.log(err);
                record = strValue;
            }
            if(record && record.docType === 'Wallet') {
                allResults.push(record);
            }
            
            result = await iterator.next();
        }
        return JSON.stringify(allResults);
    }

    // ReadAsset returns the asset stored in the world state with given id.
    async GetWallet(ctx, id) {
        const assetJSON = await ctx.stub.getState(id); // get the asset from chaincode state
        if (!assetJSON || assetJSON.length === 0) {
            throw new Error(`The wallet ${id} does not exist`);
        }
        return assetJSON.toString();
    }

    async GetWalletByUserId(ctx, assignToId) {
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();
        const wallets = [];
    
        while (!result.done) {
            const walletString = Buffer.from(result.value.value.toString()).toString('utf8');
            const wallet = JSON.parse(walletString);
    
            if (wallet.AssignToId === assignToId) {
                wallets.push(wallet);
            }
    
            result = await iterator.next();
        }
        return JSON.stringify(wallets);
    }

    async GetUserWalletByType(ctx, assignToId, walletType) {
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();   
        while (!result.done) {
            const walletString = Buffer.from(result.value.value.toString()).toString('utf8');
            const wallet = JSON.parse(walletString);
    
            if (wallet.AssignToId === assignToId && wallet.WalletType == walletType) {
                return JSON.stringify(wallet);
            }  
            result = await iterator.next();
        }
        return JSON.stringify(`Wallet of user : ${assignToId} for type : ${walletType} not found !`);
    }

    async GetWalletByPrivateKey(ctx, privateKey) {

        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();
    
        while (!result.done) {
            const walletString = Buffer.from(result.value.value.toString()).toString('utf8');
            const wallet = JSON.parse(walletString);
    
            if (wallet.PrivateKey === privateKey && wallet.Status == 0) {
                return JSON.stringify(wallet);
            }
    
            result = await iterator.next();
        }
    
        return JSON.stringify(`Wallet of sender not found !`);
    }

    async GetWalletByPublicKey(ctx, publicKey) {

        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();
    
        while (!result.done) {
            const walletString = Buffer.from(result.value.value.toString()).toString('utf8');
            const wallet = JSON.parse(walletString);
    
            if (wallet.PublicKey === publicKey && wallet.Status == 0) {
                return JSON.stringify(wallet);
            }
    
            result = await iterator.next();
        }
    
        return JSON.stringify(`Wallet of receiver not found !`);

    }

    // CreateWallet issues a new wallet to the world state with given details.
    async CreateWallet(ctx, id, privateKey, publicKey, balance, walletType, assignToId, assignToType, status) {
        const exists = await this.AssetExists(ctx, id);
        if (exists) {
            throw new Error(`The wallet ${id} already exists`);
        }

        const wallet = {
            Id: id,
            PrivateKey: privateKey,
            PublicKey: publicKey,
            Balance: balance,
            WalletType: walletType,
            AssignToId: assignToId,
            AssignToType: assignToType,
            Status: status,
            docType: 'Wallet'
        };

        // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
        await ctx.stub.putState(id, Buffer.from(stringify(sortKeysRecursive(wallet))));
        return JSON.stringify(wallet);
    }

    // UpdateAsset updates an existing asset in the world state with provided parameters.
    async UpdateWallet(ctx, id, privateKey, publicKey, balance, walletType, assignToId, assignToType, status) {
        const exists = await this.AssetExists(ctx, id);
        if (!exists) {
            throw new Error(`The asset ${id} does not exist`);
        }

        // overwriting original asset with new asset
        const updatedAsset = {
            Id: id,
            PrivateKey: privateKey,
            PublicKey: publicKey,
            Balance: balance,
            WalletType: walletType,
            AssignToId: assignToId,
            AssignToType: assignToType,
            Status: status    
        };
        // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
        return ctx.stub.putState(id, Buffer.from(stringify(sortKeysRecursive(updatedAsset))));
    }

    // DeleteWallet deletes an given asset from the world state.
    async DeleteWallet(ctx, id) {
        const exists = await this.AssetExists(ctx, id);
        if (!exists) {
            throw new Error(`The asset ${id} does not exist`);
        }
        return ctx.stub.deleteState(id);
    }



    // GetAllTransactions returns all transactions found in the world state.
    async GetAllTransactions(ctx) {
        const allResults = [];
        // range query with empty string for startKey and endKey does an open-ended query of all assets in the chaincode namespace.
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();
        while (!result.done) {
            const strValue = Buffer.from(result.value.value.toString()).toString('utf8');
            let record;
            try {
                record = JSON.parse(strValue);
            } catch (err) {
                console.log(err);
                record = strValue;
            }

            if(record && record.docType === 'Transaction') {
                allResults.push(record);
            }
            
            result = await iterator.next();
        }
        return JSON.stringify(allResults);
    }

    //GetTransaction 
    async GetTransaction(ctx, id) {
        const assetJSON = await ctx.stub.getState(id); // get the asset from chaincode state
        if (!assetJSON || assetJSON.length === 0) {
            throw new Error(`The transaction ${id} does not exist`);
        }
        return assetJSON.toString();
    }

    //GetWalletTransactions : get transaction by wallet
    async GetWalletTransactions(ctx, walletId) {
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();
        const transactions = [];
    
        while (!result.done) {
            const transactionString = Buffer.from(result.value.value.toString()).toString('utf8');
            const transaction = JSON.parse(transactionString);
    
            if (transaction.ReceiverWalletId === walletId || transaction.SenderWalletId === walletId) {
                transactions.push(transaction);
            }
    
            result = await iterator.next();
        }
        return JSON.stringify(transactions);
    }

    //GetWalletReceivedTransactions : get wallet by received transaction
    async GetWalletReceivedTransactions(ctx, walletId) {
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();
        const transactions = [];
    
        while (!result.done) {
            const transactionString = Buffer.from(result.value.value.toString()).toString('utf8');
            const transaction = JSON.parse(transactionString);
    
            if (transaction.ReceiverWalletId === walletId) {
                transactions.push(transaction);
            }
    
            result = await iterator.next();
        }
        return JSON.stringify(transactions);
    }

    //GetWalletSentTransactions : get wallet by sender transaction
    async GetWalletSentTransactions(ctx, walletId) {
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();
        const transactions = [];
    
        while (!result.done) {
            const transactionString = Buffer.from(result.value.value.toString()).toString('utf8');
            const transaction = JSON.parse(transactionString);
    
            if (transaction.SenderWalletId === walletId) {
                transactions.push(transaction);
            }
    
            result = await iterator.next();
        }
        return JSON.stringify(transactions);
    }

    //GetUserTransactions : get transaction by userId
    async GetUserTransactions(ctx, userId) {
        const wallets = await this.GetWalletByUserId(ctx, userId);
        const transactions = [];
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();


        for(const wallet in wallets) {
            while (!result.done) {
                const transactionString = Buffer.from(result.value.value.toString()).toString('utf8');
                const transaction = JSON.parse(transactionString);
        
                if (transaction.ReceiverWalletId === wallet.Id || transaction.SenderWalletId === wallet.Id) {
                    transactions.push(transaction);
                }
                result = await iterator.next();
            }
        } 
        return JSON.stringify(transactions);
    }

    //GetUserReceivedTransactions : get transaction by userId
    async GetUserReceivedTransactions(ctx, userId) {
        const wallets = await this.GetWalletByUserId(ctx, userId);
        const transactions = [];
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();


        for(const wallet in wallets) {
            while (!result.done) {
                const transactionString = Buffer.from(result.value.value.toString()).toString('utf8');
                const transaction = JSON.parse(transactionString);
        
                if (transaction.ReceiverWalletId === wallet.Id) {
                    transactions.push(transaction);
                }
                result = await iterator.next();
            }
        } 
        return JSON.stringify(transactions);
    }

    //GetUserSentTransactions : get transaction by userId
    async GetUserSentTransactions(ctx, userId) {
        const wallets = await this.GetWalletByUserId(ctx, userId);
        const transactions = [];
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();


        for(const wallet in wallets) {
            while (!result.done) {
                const transactionString = Buffer.from(result.value.value.toString()).toString('utf8');
                const transaction = JSON.parse(transactionString);
        
                if (transaction.SenderWalletId === wallet.Id) {
                    transactions.push(transaction);
                }
                result = await iterator.next();
            }
        } 
        return JSON.stringify(transactions);
    }
    
    // CreateTransaction issues a new wallet to the world state with given details.
    async CreateTransaction(ctx, id, senderWalletId, receiverWalletId, qrCodeId, amount, transactionDate, status) {
        const exists = await this.AssetExists(ctx, id);
        if (exists) {
            throw new Error(`The transaction ${id} already exists`);
        }

        const transaction = {
            Id: id,
            SenderWalletId: senderWalletId,
            ReceiverWalletId: receiverWalletId,
            QrCodeId: qrCodeId,
            Amount: amount,
            TransactionDate: transactionDate,
            Status: status,
            docType: 'Transaction'    
        };

        // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
        await ctx.stub.putState(id, Buffer.from(stringify(sortKeysRecursive(transaction))));
        return JSON.stringify(transaction);
    }


    // Transaction amount A(privateKey) => B(publicKey)
    async Transaction(ctx, senderPrivateKey, receiverPublicKey, amount) {

        const walletSenderString = await this.GetWalletByPrivateKey(ctx, senderPrivateKey);
        const walletSender = JSON.parse(walletSenderString);
        if(walletSender.Balance >= amount) {
            const walletReceiverString = await this.GetWalletByPublicKey(ctx, receiverPublicKey);
            const walletReceiver = JSON.parse(walletReceiverString);

            walletSender.Balance -= amount
            // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
            await ctx.stub.putState(walletSender.Id, Buffer.from(stringify(sortKeysRecursive(walletSender))));

            walletReceiver.Balance += amount
            // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
            await ctx.stub.putState(walletReceiver.Id, Buffer.from(stringify(sortKeysRecursive(walletReceiver))));

            return JSON.stringify(`Transaction created successfully !`);
        }
        
        return JSON.stringify(`Wallet not found !`);
    }

    // AssetExists returns true when asset with given ID exists in world state.
    async AssetExists(ctx, id) {
        const assetJSON = await ctx.stub.getState(id);
        return assetJSON && assetJSON.length > 0;
    }
}

module.exports = AssetTransfer;