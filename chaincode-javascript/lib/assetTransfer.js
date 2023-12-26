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
                AssignToId: "c23c03c2-a6f4-4423-842e-68b2c25711eb",
                AssignToType: 2,
                Status: 0
            },
            {
                Id: '2144e667-6c8d-4d95-8132-21b1d735a969',
                PrivateKey: '@0001',
                PublicKey: '@0001',          
                Balance: 200,
                WalletType: 0,
                AssignToId: "cf346361-62d7-4c2e-bc3f-db9ab618e74a",
                AssignToType: 2,
                Status: 0
            },
            {
                Id: '9be3505b-0e15-4106-a56d-3cbfec1dc6b7',
                PrivateKey: '@0002',
                PublicKey: '@0002',          
                Balance: 500,
                WalletType: 0,
                AssignToId: "11476ad4-ffbd-4c98-ab9d-5a71a331249e",
                AssignToType: 2,
                Status: 0
            },
            {
                Id: 'f05944e8-f7ea-4c93-ad6c-09aa7dc07a07',
                PrivateKey: '@0003',
                PublicKey: '@0003',          
                Balance: 700,
                WalletType: 0,
                AssignToId: "e4283ad2-fbe9-4185-a402-f38c1ba46d02",
                AssignToType: 2,
                Status: 0
            }
        ];

        for (const wallet of wallets) {
            //'asset'
            wallet.docType = 'wallet';
            await ctx.stub.putState(wallet.ID, Buffer.from(stringify(sortKeysRecursive(wallet))));
        }
    }


    // CreateWallet issues a new wallet to the world state with given details.
    async CreateAsset(ctx, id, privateKey, publicKey, balance, walletType, assignToId, assignToType, status) {
        const exists = await this.AssetExists(ctx, id);
        if (exists) {
            throw new Error(`The wallet ${id} already exists`);
        }

        const wallet = {
            ID: id,
            PrivateKey: privateKey,
            PublicKey: publicKey,
            Balance: balance,
            WalletType: walletType,
            AssignToId: assignToId,
            AssignToType: assignToType,
            Status: status    
        };
        // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
        await ctx.stub.putState(id, Buffer.from(stringify(sortKeysRecursive(wallet))));
        return JSON.stringify(wallet);
    }

    // ReadAsset returns the asset stored in the world state with given id.
    async ReadAsset(ctx, id) {
        const assetJSON = await ctx.stub.getState(id); // get the asset from chaincode state
        if (!assetJSON || assetJSON.length === 0) {
            throw new Error(`The wallet ${id} does not exist`);
        }
        return assetJSON.toString();
    }
    
    async GetWalletByUserId(ctx, assignToId) {
        const assetJSON = await ctx.stub.getState(x => x.AssignToId == assignToId);
        if (!assetJSON || assetJSON.length === 0) {
            throw new Error(`The wallet ${id} does not exist`);
        }
        return assetJSON.toString();
    }
    // UpdateAsset updates an existing asset in the world state with provided parameters.
    async UpdateAsset(ctx, id, code, privateKey, publicKey, balance) {
        const exists = await this.AssetExists(ctx, id);
        if (!exists) {
            throw new Error(`The asset ${id} does not exist`);
        }

        // overwriting original asset with new asset
        const updatedAsset = {
            ID: id,
            Code: code,
            PrivateKey: privateKey,
            PublicKey: publicKey,
            Balance: balance,
        };
        // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
        return ctx.stub.putState(id, Buffer.from(stringify(sortKeysRecursive(updatedAsset))));
    }

    // DeleteAsset deletes an given asset from the world state.
    async DeleteAsset(ctx, id) {
        const exists = await this.AssetExists(ctx, id);
        if (!exists) {
            throw new Error(`The asset ${id} does not exist`);
        }
        return ctx.stub.deleteState(id);
    }

    // AssetExists returns true when asset with given ID exists in world state.
    async AssetExists(ctx, id) {
        const assetJSON = await ctx.stub.getState(id);
        return assetJSON && assetJSON.length > 0;
    }

    // TransferAsset updates the owner field of asset with given id in the world state.
    async TransferAsset(ctx, id, newOwner) {
        const assetString = await this.ReadAsset(ctx, id);
        const asset = JSON.parse(assetString);
        const oldOwner = asset.Owner;
        asset.Owner = newOwner;
        // we insert data in alphabetic order using 'json-stringify-deterministic' and 'sort-keys-recursive'
        await ctx.stub.putState(id, Buffer.from(stringify(sortKeysRecursive(asset))));
        return oldOwner;
    }

    // GetAllAssets returns all assets found in the world state.
    async GetAllAssets(ctx) {
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
            allResults.push(record);
            result = await iterator.next();
        }
        return JSON.stringify(allResults);
    }
}

module.exports = AssetTransfer;