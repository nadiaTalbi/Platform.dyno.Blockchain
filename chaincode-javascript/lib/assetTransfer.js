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
const { v4: uuidv4 } = require('uuid');

class AssetTransfer extends Contract {

    async InitLedger(ctx) {
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

    async GetWalletsByUserId(ctx, assignedToId) {
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();
        const wallets = [];
    
        while (!result.done) {
            const walletString = Buffer.from(result.value.value.toString()).toString('utf8');
            const wallet = JSON.parse(walletString);
    
            if (wallet.AssignedToId === assignedToId) {
                wallets.push(wallet);
            }
    
            result = await iterator.next();
        }
        return JSON.stringify(wallets);
    }

    async GetUserWalletByType(ctx, assignedToId, walletType) {
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();   
        while (!result.done) {
            const walletString = Buffer.from(result.value.value.toString()).toString('utf8');
            const wallet = JSON.parse(walletString);
    
            if (wallet.AssignedToId === assignedToId && wallet.WalletType == walletType) {
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
    async CreateWallet(ctx, id, privateKey, publicKey, balance, walletType, assignedToId, assignedToType, status) {
        const exists = await this.AssetExists(ctx, id);
        if (exists) {
            throw new Error(`The wallet ${id} already exists`);
        }

        const wallet = {
            Id: id,
            PrivateKey: privateKey,
            PublicKey: publicKey,
            Balance: parseFloat(balance),
            WalletType: parseInt(walletType),
            AssignedToId: assignedToId,
            AssignedToType: parseInt(assignedToType),
            Status: parseInt(status),
            docType: 'Wallet'
        };

        // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
        await ctx.stub.putState(id, Buffer.from(stringify(sortKeysRecursive(wallet))));
        return JSON.stringify(wallet);
    }

    // UpdateAsset updates an existing asset in the world state with provided parameters.
    async UpdateWallet(ctx, id, privateKey, publicKey, balance, walletType, assignedToId, assignedToType, status) {
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
            AssignedToId: assignedToId,
            AssignedToType: assignedToType,
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

    // DeleteWallet deletes an given asset from the world state.
    async DeleteWalletsbyUserId(ctx, userId) {       
        const wallets = await this.GetWalletsByUserId(ctx, userId);
        for(const wallet in wallets) {
            ctx.stub.deleteState(wallet.id);
        }
        return JSON.stringify("Wallet has been deleted for user !");
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
    async Transaction(ctx, id, senderPrivateKey, receiverPublicKey, amount, qrCodeId, transactionDate, status) {

        const walletSenderString = await this.GetWalletByPrivateKey(ctx, senderPrivateKey);
        const walletSender = JSON.parse(walletSenderString);
        if(walletSender.Balance >= amount) {
            const walletReceiverString = await this.GetWalletByPublicKey(ctx, receiverPublicKey);
            const walletReceiver = JSON.parse(walletReceiverString);
            if(walletReceiver.Id == walletSender.Id) {
                return JSON.stringify(`sender and receiver are the same wallet!`);
            }

            walletSender.Balance = walletSender.Balance - parseFloat(amount)
            // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
            await ctx.stub.putState(walletSender.Id, Buffer.from(stringify(sortKeysRecursive(walletSender))));

            walletReceiver.Balance = walletReceiver.Balance + parseFloat(amount)
            // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
            await ctx.stub.putState(walletReceiver.Id, Buffer.from(stringify(sortKeysRecursive(walletReceiver))));

            const transaction = {
                Id: id,
                SenderWalletId: walletSender.Id,
                ReceiverWalletId: walletReceiver.Id,
                QrCodeId: qrCodeId,
                Amount: parseFloat(amount),
                TransactionDate: transactionDate,
                Status: status,
                docType: 'Transaction'    
            };
    
            // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
            await ctx.stub.putState(id, Buffer.from(stringify(sortKeysRecursive(transaction))));

            return JSON.stringify(`Transaction created successfully !`);
        }
        
        return JSON.stringify(`Wallet not found !`);
    }


    async ListTransactions(ctx, id, senderPrivateKey, receiverTransactions, totalAmount, qrCodeId, transactionDate, status) {

        const walletSenderString = await this.GetWalletByPrivateKey(ctx, senderPrivateKey);
        
        if(walletSenderString == null) {
            return JSON.stringify(`Wallet not found !`);
        }
        const walletSender = JSON.parse(walletSenderString);
        
        
        if(walletSender.Balance >= totalAmount) {
            console.log(receiverTransactions);
            for(var element of receiverTransactions){
                console.log("Amount", element.amount);
                console.log("Receiver", element.receiverPublicKey);
                const walletReceiverString = await this.GetWalletByPublicKey(ctx, element.receiverPublicKey);
                
                if(walletReceiverString == null) {
                    return JSON.stringify(`Wallet not found !`);
                }
                const walletReceiver = JSON.parse(walletReceiverString);
                
                if(walletReceiver.Id == walletSender.Id) {
                    return JSON.stringify(`sender and receiver are the same wallet!`);
                }  

                walletReceiver.Balance = walletReceiver.Balance + parseFloat(element.amount)
                await ctx.stub.putState(walletReceiver.Id, Buffer.from(stringify(sortKeysRecursive(walletReceiver))));  
                
                const transaction = {
                    Id: uuidv4(),
                    SenderWalletId: walletSender.Id,
                    ReceiverWalletId: walletReceiver.Id,
                    QrCodeId: qrCodeId,
                    Amount: parseFloat(element.amount),
                    TransactionDate: transactionDate,
                    Status: status,
                    docType: 'Transaction'    
                };                            
                await ctx.stub.putState(transaction.Id, Buffer.from(stringify(sortKeysRecursive(transaction))));
            };
            
            walletSender.Balance = walletSender.Balance - parseFloat(totalAmount)
            await ctx.stub.putState(walletSender.Id, Buffer.from(stringify(sortKeysRecursive(walletSender))));                             
            
            return JSON.stringify(`Transaction created successfully !`);
        }
        
        return JSON.stringify(`The amount of the wallet is insufficient!`);
    }

    // AssetExists returns true when asset with given ID exists in world state.
    async AssetExists(ctx, id) {
        const assetJSON = await ctx.stub.getState(id);
        return assetJSON && assetJSON.length > 0;
    }
}

module.exports = AssetTransfer;