pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
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

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_)  {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IDao {
    function rewardToVip(uint rewards) external;
    function rewardToNode(uint rewards) external;
}

contract TokenReceiver {
    constructor(address token) {
        IERC20(token).approve(msg.sender, type(uint256).max);
    }
}

contract FeeReceiver {}

contract YUNA is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    TokenReceiver public tokenReceiver;
    FeeReceiver public feeReceiver1;
    FeeReceiver public feeReceiver2;
    FeeReceiver public feeReceiver3;
    bool private swapping;

    address public constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant tokenOwner = 0x0000000000000000000000000000000000000000;
    address public constant POOL = 0x0000000000000000000000000000000000000000;

    address public fund1 = 0x0000000000000000000000000000000000000000;
    address public fund2 = 0x0000000000000000000000000000000000000000;
    address public fund3 = 0x0000000000000000000000000000000000000000;
    address public fund4 = 0x0000000000000000000000000000000000000000;
    address public fund5 = 0x0000000000000000000000000000000000000000;
    address public dao;

    uint256 public numTokensSellToSwap = 1000 * 1e18;// usdt
    
    uint256 public buyLiquifyFee = 5;
    uint256 public buyNodeFee = 10; 
    uint256 public buyDaoFee = 10; 
    uint256 public buyFundFee = 10;
    
    uint256 public sellBurnFee = 5;
    uint256 public sellNodeFee = 10; 
    uint256 public sellDaoFee = 10; 
    uint256 public sellFundFee = 10;

    uint256 public dumpFee1 = 65;
    uint256 public dumpFee2 = 115;
    uint256 public extraFee = 200;

    // exlcude from fees and max transaction amount
    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public isPair;
    mapping (address => uint) public inTime;
    mapping (address => uint) public principalOf;
    mapping(uint => uint) public dailyPriceOf;

    uint public startTime;
    uint public freezeTime = 3;

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() ERC20("YUNA", "YUNA") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(ROUTER);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), USDT);

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        isPair[_uniswapV2Pair] = true;

        tokenReceiver = new TokenReceiver(USDT);
        feeReceiver1 = new FeeReceiver();
        feeReceiver2 = new FeeReceiver();
        feeReceiver3 = new FeeReceiver();

        // exclude from paying fees or having max transaction amount
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[tokenOwner] = true;
        isExcludedFromFees[POOL] = true;
        isExcludedFromFees[fund1] = true;
        isExcludedFromFees[fund2] = true;
        isExcludedFromFees[fund3] = true;
        isExcludedFromFees[fund4] = true;
        isExcludedFromFees[fund5] = true;
        
        _approve(address(this), ROUTER, type(uint).max);
        IERC20(USDT).approve(ROUTER, type(uint).max);
        _mint(tokenOwner, 2100 * 1e22);
    }

    receive() external payable {}

    function startTrade() external onlyOwner {
        require(startTime == 0, "already start");
        startTime = block.timestamp;
    }

    function init(address _dao) external onlyOwner {
        require(_dao != address(0), "zero address");
        require(dao == address(0), "already set");
        dao = _dao;
        isExcludedFromFees[dao] = true;
    }

    function setPair(address pair) external onlyOwner {
        require(pair != address(0), "zero address");
        isPair[pair] = true;
    }

    function setFunds(address[5] memory _funds) external onlyOwner {
        for (uint i; i < 5; i++) {
            require(_funds[i] != address(0));
        }
        fund1 = _funds[0];
        fund2 = _funds[1];
        fund3 = _funds[2];
        fund4 = _funds[3];
        fund5 = _funds[4];
    }

    function setFreezeTime(uint _freezeTime) external onlyOwner {
        require(_freezeTime <= 60);
        freezeTime = _freezeTime;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFees[accounts[i]] = excluded;
        }
    }

    function reSync(uint amount) external {
        require(msg.sender == POOL, "invalid caller");
        uint pairBalance = balanceOf(address(uniswapV2Pair));
        uint maxAmount = pairBalance / 3;
        require(amount < maxAmount);
        super._transfer(uniswapV2Pair, POOL, amount);
        IUniswapV2Pair(uniswapV2Pair).sync();
    }
    
    function setBuyFees(uint _buyLiquifyFee, uint _buyNodeFee, uint _buyDaoFee, uint _buyFundFee) external onlyOwner {
        require(_buyLiquifyFee + _buyNodeFee + _buyDaoFee + _buyFundFee < 400, "fee too hight");
        buyLiquifyFee = _buyLiquifyFee;
        buyNodeFee = _buyNodeFee;
        buyDaoFee = _buyDaoFee;
        buyFundFee = _buyFundFee;
    }

    function setSellFees(uint _sellBurnFee, uint _sellNodeFee, uint _sellDaoFee, uint _sellFundFee) external onlyOwner {
        require(_sellBurnFee + _sellNodeFee + _sellDaoFee + _sellFundFee < 400, "fee too hight");
        sellBurnFee = _sellBurnFee;
        sellNodeFee = _sellNodeFee;
        sellDaoFee = _sellDaoFee;
        sellFundFee = _sellFundFee;
    }

    function setExtraFee(uint _extraFee) external onlyOwner {
        require(_extraFee < 500, "fee too hight");
        extraFee = _extraFee;
    }

    function setDumpFee(uint _dumpFee1, uint _dumpFee2) external onlyOwner {
        require(_dumpFee1 + _dumpFee2 < 500, "fee too hight");
        dumpFee1 = _dumpFee1;
        dumpFee2 = _dumpFee2;
    }

    function setNumTokensSellToSwap(uint256 value) external onlyOwner {
        numTokensSellToSwap = value;
    }

    function rescueERC20(address token, address to, uint amount) external onlyOwner {
        if (token == address(this)) {
            super._transfer(address(this), to, amount);
        } else {
            IERC20(token).transfer(to, amount);
        }  
    }

    function rescueETH(address to, uint amount) external onlyOwner {
        (bool success,) = address(to).call{value: amount}("");
        require(success);
    }

    function getMinSwapToken() public view returns (uint) {
        if (startTime == 0) return type(uint256).max;
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = address(this);
        uint[] memory amountOuts = uniswapV2Router.getAmountsOut(numTokensSellToSwap, path);
        return amountOuts[1];
    }

    function _updateDailyPrice() private {
        uint dayTime = (block.timestamp - block.timestamp % 1 days);
        if (dailyPriceOf[dayTime] == 0) {
            dailyPriceOf[dayTime] = getPrice();
        }
    }

    function getDailyPrice() public view returns (uint256, uint256) {
        uint dayTime = (block.timestamp - block.timestamp % 1 days);
        uint curPrice = getPrice();
        return (dailyPriceOf[dayTime], curPrice);
    }

    function getPrice() public view returns (uint256) {
        address token0 = IUniswapV2Pair(uniswapV2Pair).token0();
        (uint256 r0, uint256 r1, ) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        if (r0 == 0 || r1 == 0) {
            return 0;
        }
        if (token0 == USDT) {
            return 1e18 * r0 / r1;
        } 
        return 1e18 * r1 / r0;
    }

    function getDumpFee() public view returns (uint) {
        uint dayTime = (block.timestamp - block.timestamp % 1 days);
        uint dayPrice = dailyPriceOf[dayTime];
        uint curPrice = getPrice();
        if (dayPrice != 0 && dayPrice > curPrice) {
            uint percent = (dayPrice - curPrice) * 100 / dayPrice;
            if (percent > 5) {
                return dumpFee2;
            }
            return dumpFee1;
        }
        return 0;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        _updateDailyPrice();

        if (from == POOL || to == POOL) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        uint minSwapToken = getMinSwapToken();
        if( contractTokenBalance >= minSwapToken &&
            !swapping &&
            !isPair[from]
        ) {
            swapAndDividend(minSwapToken);
        } 

        uint256 feeBalance1 = balanceOf(address(feeReceiver1));
        if( feeBalance1 >= minSwapToken &&
            !swapping &&
            !isPair[from]
        ) {
            swapAndDividendExtraFee1(minSwapToken);
        }

        uint256 feeBalance2 = balanceOf(address(feeReceiver2));
        if( feeBalance2 >= minSwapToken &&
            !swapping &&
            !isPair[from]
        ) {
            swapAndDividendExtraFee2(minSwapToken);
        }

        uint256 feeBalance3 = balanceOf(address(feeReceiver3));
        if( feeBalance3 >= minSwapToken &&
            !swapping &&
            !isPair[from]
        ) {
            swapAndDividendExtraFee3(minSwapToken);
        }

        bool takeFee = !swapping;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }
    
    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender, 
        address recipient, 
        uint256 amount, 
        bool takeFee
    ) private {
        if(takeFee) {
            uint256 feeToThis;
            uint256 feeToBurn;
            uint oAmount = amount;
            if(isPair[sender]) { //buy
                require(startTime > 0);
                feeToThis = buyNodeFee + buyDaoFee + buyFundFee;
                address[] memory path = new address[](2);
                path[0] = USDT;
                path[1] = address(this);
                uint[] memory amountsIn = uniswapV2Router.getAmountsIn(amount, path);
                principalOf[recipient] += amountsIn[0];

                if (buyLiquifyFee > 0) {
                    uint _liquifyAmount = amount * buyLiquifyFee / 1000;
                    super._transfer(sender, address(feeReceiver3), _liquifyAmount);
                    amount -= _liquifyAmount;
                }
                
                if (freezeTime > 0) {
                    inTime[recipient] = block.timestamp;
                }
            } else if (isPair[recipient]) {
                require(startTime > 0);
                feeToThis = sellNodeFee + sellDaoFee + sellFundFee;
                feeToBurn = sellBurnFee;
                uint _dumpFee = getDumpFee();
                if (_dumpFee > 0) {
                    uint _dumpFeeAmount = oAmount * _dumpFee / 1000;
                    super._transfer(sender, address(feeReceiver2), _dumpFeeAmount);
                    amount -= _dumpFeeAmount; 
                }
                uint extraFeeAmount;
                address[] memory path1 = new address[](2);
                path1[0] = address(this);
                path1[1] = USDT;
                uint[] memory amountsOut = uniswapV2Router.getAmountsOut(amount, path1);
                uint amountOut = amountsOut[1];
                if (principalOf[sender] >= amountOut) {
                    principalOf[sender] -= amountOut;
                } else {
                    uint profit = amountOut - principalOf[sender];
                    uint[] memory amountsIn = uniswapV2Router.getAmountsIn(profit, path1);
                    extraFeeAmount = amountsIn[0] * extraFee / 1000;
                    principalOf[sender] = 0;
                }
                if (extraFeeAmount > 0) {
                    super._transfer(sender, address(feeReceiver1), extraFeeAmount);
                    amount -= extraFeeAmount;
                } 
               
                if (freezeTime > 0) {
                    require(block.timestamp >= inTime[sender] + freezeTime);
                }
            } else {
                if (freezeTime > 0) {
                    inTime[recipient] = block.timestamp;
                }
            }

            if(feeToBurn > 0) {
                uint256 feeAmount = oAmount * feeToBurn / 1000;
                super._transfer(sender, address(0xdead), feeAmount);
                amount -= feeAmount;
            }

            if(feeToThis > 0) {
                uint256 feeAmount = oAmount * feeToThis / 1000;
                super._transfer(sender, address(this), feeAmount);
                amount -= feeAmount;
            }
        }
        super._transfer(sender, recipient, amount);
    }

    function swapAndDividend(uint256 tokenAmount) private lockTheSwap {
        uint totalBuyShare = buyNodeFee + buyDaoFee + buyFundFee;
        uint totalSellShare = sellNodeFee + sellDaoFee + sellFundFee;

        uint256 usdtReceived = IERC20(USDT).balanceOf(address(tokenReceiver));
        swapTokensForUSDT(tokenAmount, address(tokenReceiver));
        usdtReceived = IERC20(USDT).balanceOf(address(tokenReceiver)) - usdtReceived;

        uint toNode = usdtReceived * (buyNodeFee + sellNodeFee) / (totalBuyShare + totalSellShare);
        IERC20(USDT).transferFrom(address(tokenReceiver), dao, toNode);
        IDao(dao).rewardToNode(toNode);

        uint toDao = usdtReceived * (buyDaoFee + sellDaoFee) / (totalBuyShare + totalSellShare);
        IERC20(USDT).transferFrom(address(tokenReceiver), dao, toDao);
        IDao(dao).rewardToVip(toDao);

        uint left = usdtReceived - toNode - toDao;
        IERC20(USDT).transferFrom(address(tokenReceiver), fund1, left);
    }

    function swapAndDividendExtraFee1(uint256 tokenAmount) private lockTheSwap {
        super._transfer(address(feeReceiver1), address(this), tokenAmount);

        uint256 usdtReceived = IERC20(USDT).balanceOf(address(tokenReceiver));
        swapTokensForUSDT(tokenAmount, address(tokenReceiver));
        usdtReceived = IERC20(USDT).balanceOf(address(tokenReceiver)) - usdtReceived;
        uint quarter = usdtReceived / 4;
        IERC20(USDT).transferFrom(address(tokenReceiver), fund3, quarter);
        IERC20(USDT).transferFrom(address(tokenReceiver), fund4, quarter);
        IERC20(USDT).transferFrom(address(tokenReceiver), fund5, quarter);

        uint left = usdtReceived - quarter * 3;
        IERC20(USDT).transferFrom(address(tokenReceiver), dao, left);
        IDao(dao).rewardToVip(left);
    }

    function swapAndDividendExtraFee2(uint256 tokenAmount) private lockTheSwap {
        super._transfer(address(feeReceiver2), address(this), tokenAmount);
        swapTokensForUSDT(tokenAmount, fund2);
    }

    function swapAndDividendExtraFee3(uint256 tokenAmount) private lockTheSwap {
        super._transfer(address(feeReceiver3), address(this), tokenAmount);
        uint256 half = tokenAmount / 2;
        uint256 initialBalance = IERC20(USDT).balanceOf(address(tokenReceiver));
        swapTokensForUSDT(half, address(tokenReceiver));
        uint256 newBalance = IERC20(USDT).balanceOf(address(tokenReceiver)) - initialBalance;
        IERC20(USDT).transferFrom(address(tokenReceiver), address(this), newBalance);

        uniswapV2Router.addLiquidity(
            address(this),
            USDT,
            half,
            newBalance,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
        uint left = IERC20(USDT).balanceOf(address(this));
        if (left > 0) {
            IERC20(USDT).transfer(fund1, left);
        }
    }

    function swapTokensForUSDT(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}