const MockERC20 = artifacts.require("mocks/MockERC20.sol")
const WETH9 = artifacts.require("mocks/WETH9.sol")
const Pocket = artifacts.require("mocks/MockPocket.sol")
const PocketSwapFactory = artifacts.require("pocketswap/PocketSwapFactory.sol")
const PocketSwapRouter = artifacts.require("pocketswap/PocketSwapRouter.sol")
const PocketSwap = artifacts.require("PocketSwap.sol")

contract("PocketSwap: Test K-error", accounts => {
    let usdt;
    let weth;
    let pocket;
    let pocketSwapFactory;
    let router;
    let swap;
    let account = {address: accounts[0]};

    before(async () => {
        usdt = await MockERC20.new();
        console.log("usdt deployed to:", usdt.address);
        weth = await WETH9.new();
        console.log("weth deployed to:", weth.address);
        pocket = await Pocket.new();
        console.log("pocket deployed to:", pocket.address);
        pocketSwapFactory = await PocketSwapFactory.new(pocket.address);
        console.log("pocketSwapFactory deployed to:", pocketSwapFactory.address);
        router = await PocketSwapRouter.new(
            pocketSwapFactory.address,
            weth.address,
            pocket.address
        );
        console.log("router deployed to:", router.address);
        swap = await PocketSwap.new(
            router.address,
            pocketSwapFactory.address,
            pocket.address,
            weth.address
        );
        console.log("swap deployed to:", swap.address);
    })

    it("test K-error", async () => {
        let overrides = {
            value: 0,
            gasLimit: 3828084,
            gasPrice: 1000000000,
        };

        console.log("mint usdt\n");

        // mint usdt
        let maxAmount = web3.utils.toWei("1000000000");
        let tx = await usdt.mint(account.address, maxAmount, overrides);

        console.log(`mint ${maxAmount} usdt to ${account.address}`);
        console.log(`tx ${tx.receipt.transactionHash}`);
        let balanceOf = await usdt.balanceOf(account.address);
        console.log(
            `${account.address} balanceOf usdt ${web3.utils.fromWei(
                balanceOf.toString()
            )}\n`
        );

        // mint weth
        console.log("mint weth\n");
        maxAmount = web3.utils.toWei("100");
        tx = await weth.deposit({
            value: maxAmount,
            gasLimit: 3828084,
            gasPrice: 1000000000,
        });
        console.log(`mint ${maxAmount} weth to ${account.address}`);
        console.log(`tx ${tx.receipt.transactionHash}`);
        balanceOf = await weth.balanceOf(account.address);
        console.log(
            `${account.address} balanceOf weth ${web3.utils.fromWei(
                balanceOf.toString()
            )}\n`
        );

        console.log(`start add liquidity usdt-pocket\n`);

        // const maxAmount = web3.utils.toWei('10');
        await usdt.approve(
            swap.address,
            web3.utils.toWei("100000"),
            overrides
        );

        await pocket.approve(
            swap.address,
            web3.utils.toWei("100000"),
            overrides
        );

        let addLpParam = [
            usdt.address,
            pocket.address,
            account.address,
            web3.utils.toWei("1000"),
            web3.utils.toWei("1000"),
            0,
            0,
            2651726900,
        ];

        tx = await swap.addLiquidity(addLpParam, {
            value: 0,
            gasLimit: 38280840,
            gasPrice: 1000000000,
        });

        console.log(`tx ${tx.receipt.transactionHash}`);

        let LpAddress = await pocketSwapFactory.getPair(usdt.address, pocket.address);
        console.log(`LpAddress ${LpAddress}`);

        console.log(`swap usdt to pocket`);
        const amountIn = web3.utils.toWei('1');
        let swapParam = [
            usdt.address,
            pocket.address,account.address, 2651726900, amountIn, 0
        ]

        console.log(`swap pocket to usdt\n`);
        tx = await swap.swap(swapParam, {
            value: 0,
            gasLimit: 38280840,
            gasPrice: 1000000000,
        })
        console.log(`tx ${tx.receipt.transactionHash}\n`);

        console.log(`swap usdt to pocket\n`);
        console.log(`k-error.?.?\n`);
        swapParam = [
            pocket.address,
            usdt.address,account.address, 2651726900, amountIn, 0
        ]

        tx = await swap.swap(swapParam, {
            value: 0,
            gasLimit: 38280840,
            gasPrice: 1000000000,
        })

        console.log(`tx ${tx.receipt.transactionHash}\n`);

    })
})