//SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeERC20 {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IToken {
    function reSync(uint amount) external;
}

interface IDao {
    function stakeInBy(address user, uint usdtAmount, uint lockDays) external;
    function claimBy(address user, uint rewards) external;
}

interface IOracle {
    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint);
}

contract Pool is Ownable {
    using SafeERC20 for IERC20;
    uint256 private _status;
    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }

    struct ItemInfo {
        address account;
        uint principal;
        uint index;
        uint startTime;
        uint lockDays;
        uint claimedRewards;
        bool isOut;
    }
    mapping (uint => ItemInfo) public itemInfoByIndex;
    uint public totalItemNum;

    struct UserInfo {
        uint totalIn;
        uint redeemed;
        uint claimedRewards;
        uint[] indexesOf;
    }
    mapping(address => UserInfo) public userInfo;

    uint public startTime;
    uint public minToken = 100 * 1e18;
    uint public maxToken = 10000 * 1e18;
    uint public slippage = 3;
    uint public fee = 10;

    uint public totalStaked;
    uint public totalRedeemed;

    uint256 constant public ONE_DAY = 1 days;
    address constant public ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant public USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public VAULT;
    address public TOKEN;
    address public DAO;

    constructor() {
        IERC20(USDT).safeApprove(ROUTER, type(uint).max);
    }

    function init(address token, address dao) public onlyOwner {
        require(TOKEN == address(0) && DAO == address(0));
        TOKEN = token;
        DAO = dao;
        IERC20(token).safeApprove(ROUTER, type(uint).max);
    }

    function setStartTime(uint _timeStamp) external onlyOwner {
        require(startTime == 0);
        startTime = _timeStamp;
    }

    function setVault(address vault) external onlyOwner {
        require(vault != address(0));
        VAULT = vault;
    }

    function setSlippage(uint _slippage) external onlyOwner {
        require(_slippage <= 20);
        slippage = _slippage;
    }

    function setFee(uint _fee) external onlyOwner {
        require(_fee <= 20);
        fee = _fee;
    }

    function setMinAndMaxToken(uint _minToken, uint _maxToken) external onlyOwner {
        require(_minToken < _maxToken);
        minToken = _minToken;
        maxToken = _maxToken;
    }

    function stake(uint usdtAmount, uint lockDays) external nonReentrant {
        require(startTime > 0);
        require(tx.origin == msg.sender);
        require(usdtAmount >= minToken && usdtAmount <= maxToken);
        require(lockDays == 30 || lockDays == 90 || lockDays == 270);

        UserInfo storage ui = userInfo[msg.sender];
        ui.totalIn += usdtAmount;
        
        IERC20(USDT).safeTransferFrom(msg.sender, address(this), usdtAmount);
        _addLiquidity(usdtAmount);

        totalItemNum++;
        ItemInfo memory ii;
        ii.account = msg.sender;
        ii.principal = usdtAmount;
        ii.index = totalItemNum;
        ii.startTime = block.timestamp;
        ii.lockDays = lockDays;
        ii.claimedRewards = 0;
        ii.isOut = false;
        itemInfoByIndex[totalItemNum] = ii;
        ui.indexesOf.push(totalItemNum);

        totalStaked += usdtAmount;

        IDao(DAO).stakeInBy(msg.sender, usdtAmount, lockDays);
	}

    function _addLiquidity(uint usdtAmount) private {
        uint half = usdtAmount / 2;
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = TOKEN;
        uint[] memory amountOuts = IRouter(ROUTER).getAmountsOut(half, path);
        uint minAmount = amountOuts[1] * (100 - slippage) / 100;

        uint tokenReceived = IERC20(TOKEN).balanceOf(address(this));
        IRouter(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            half,
            minAmount,
            path,
            address(this),
            block.timestamp
        );
        tokenReceived = IERC20(TOKEN).balanceOf(address(this)) - tokenReceived;

        (, uint usdtUsed,) = IRouter(ROUTER).addLiquidity(
            TOKEN,
            USDT,
            tokenReceived,
            half,
            0,
            0,
            address(0),
            block.timestamp
        );
        if (half > usdtUsed) {
            IERC20(USDT).safeTransfer(VAULT, half - usdtUsed);
        }
    }

    function withdrawPrincipal(uint index) external nonReentrant {
        require(tx.origin == msg.sender);
        ItemInfo storage ii = itemInfoByIndex[index];
        require(!ii.isOut);
        require(msg.sender == ii.account);
        require(block.timestamp >= ii.startTime + ii.lockDays * ONE_DAY);
        ii.isOut = true;

        UserInfo storage ui = userInfo[msg.sender];
        ui.redeemed += ii.principal;
        totalRedeemed += ii.principal;

        address[] memory path = new address[](2);
        path[0] = TOKEN;
        path[1] = USDT;
        uint tokenBalance = IERC20(TOKEN).balanceOf(address(this));
        IRouter(ROUTER).swapTokensForExactTokens(
            ii.principal, 
            tokenBalance, 
            path, 
            ii.account, 
            block.timestamp
        );
        
        uint spentToken = tokenBalance - IERC20(TOKEN).balanceOf(address(this));
        IToken(TOKEN).reSync(spentToken);
    }

    function pendingReward(uint index) public view returns (uint) {
        ItemInfo storage ii = itemInfoByIndex[index];
        if (ii.startTime == 0) return 0;
        uint rate = 30;
        if (ii.lockDays == 90) {
            rate = 60;
        } else if (ii.lockDays == 270) {
            rate = 120;
        }

        uint rewardsPerSec = ii.principal * rate / 10000 / ONE_DAY;
        uint passed = block.timestamp - ii.startTime;
        uint max = ii.lockDays * ONE_DAY;
        if (passed > max) {
            passed = max;
        }
        return rewardsPerSec * passed - ii.claimedRewards; 
    }

    function claim(uint index) external nonReentrant {
        require(tx.origin == msg.sender);
        ItemInfo storage ii = itemInfoByIndex[index];
        require(ii.account == msg.sender);
        uint pending = pendingReward(index);
        require(pending > 0);

        ii.claimedRewards += pending;
        UserInfo storage ui = userInfo[msg.sender];
        ui.claimedRewards += pending;

        uint needUsdt = pending * 225 / 100;

        address[] memory path = new address[](2);
        path[0] = TOKEN;
        path[1] = USDT;
        uint tokenBalance = IERC20(TOKEN).balanceOf(address(this));
        IRouter(ROUTER).swapTokensForExactTokens(
            needUsdt, 
            tokenBalance, 
            path, 
            address(this), 
            block.timestamp
        );

        uint feeAmount = pending * fee / 100;
        IERC20(USDT).safeTransfer(VAULT, feeAmount);
        IERC20(USDT).safeTransfer(ii.account, pending - feeAmount);
        uint toDao = needUsdt - pending;
        IERC20(USDT).safeTransfer(DAO, toDao);
        IDao(DAO).claimBy(msg.sender, toDao);
        
        uint spentToken = tokenBalance - IERC20(TOKEN).balanceOf(address(this));
        IToken(TOKEN).reSync(spentToken);
    }

    function rescueToken(address token, address to, uint amount) external onlyOwner {
        require(token != TOKEN);
        IERC20(token).safeTransfer(to, amount);
    }

    function rescueETH(address to, uint amount) external onlyOwner {
        (bool success,) = address(to).call{value: amount}("");
        require(success);
    }

    function getUserItems(address user) public view returns (ItemInfo[] memory) {
        UserInfo storage ui = userInfo[user];
        uint[] memory indexes = ui.indexesOf;

        uint len = indexes.length;
        ItemInfo[] memory items = new ItemInfo[](len);
        for (uint256 i; i < len; i++) {
            uint index = indexes[i];
            ItemInfo storage ii = itemInfoByIndex[index];
            items[i].account = ii.account;
            items[i].principal = ii.principal;
            items[i].index = ii.index;
            items[i].startTime = ii.startTime;
            items[i].lockDays = ii.lockDays;
            items[i].claimedRewards = ii.claimedRewards;
            items[i].isOut = ii.isOut;
        }
        return items;
    }

    function getUserItemIndexes(address user) public view returns(uint[] memory) {
        UserInfo storage ui = userInfo[user];
        return ui.indexesOf;
    }

    function getUserStaking(address user) public view returns(uint) {
        UserInfo storage ui = userInfo[user];
        return ui.totalIn - ui.redeemed;
    }
}