
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.5.4/index.ts';
import { assertEquals } from 'https://deno.land/std@0.170.0/testing/asserts.ts';

Clarinet.test({
    name: "the get-count function testing",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const testNum = '42';
        let deployerWallet = accounts.get('deployer')!;

        let block = chain.mineBlock([
            Tx.contractCall(
                `${deployerWallet.address}.bbtc`,
                'get-count',
                [new Account(deployerWallet)],
                deployerWallet.address
            )
        ]);

        assertEquals(block.receipts.length , 1);
        console.log(block.receipts[0]);
    },
});
