// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DTTPresale {
    using SafeMath for uint256;
    IBEP20 public BNB20Token;
    address public owner;
    uint256 public TokenCountPerEth = 100000000000000000000; // include the 0's for the token decimals
    uint256 public uncliamedSoldTokens;
    uint256 public totalSoldTokens;
    uint256 public totalParticipants;
    uint256 public presalePeriod = 90 days;
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;
    bool public isPresaleEnded = false;
    struct FundWallet {
        address wallet;
        uint256 percent;
    }
    uint256 public fundIndex = 0;
    mapping(address => uint256) public tokenBalance;
    mapping(address => uint256) public withdrawBalance;
    mapping(uint256 => FundWallet) public fundList;

    modifier onlyOwner(address _user) {
        require(owner == _user, "Ownable: caller is not the owner");
        _;
    }

    constructor(address _BNB20Token, address _owner) {
        BNB20Token = IBEP20(_BNB20Token);
        owner = _owner;
        presaleStartTime = block.timestamp;
        presaleEndTime = block.timestamp.add(presalePeriod);
    }

    function grantOwnership(address _owner) external onlyOwner(msg.sender) {
        owner = _owner;
    }

    function deposit(uint256 amount) public onlyOwner(msg.sender) {
        BNB20Token.transferFrom(msg.sender, address(this), amount);
    }

    function updatePresaleEndStatus(bool _status) public onlyOwner(msg.sender) {
        isPresaleEnded = _status;
        presaleEndTime = block.timestamp;
    }

    function setFundList(
        address[] calldata addressList,
        uint256[] calldata percentList
    ) external onlyOwner(msg.sender) {
        require(
            addressList.length == percentList.length,
            "Address length should be same percent list length"
        );
        uint256 all_percent = 0;
        for (uint256 i = 0; i < percentList.length; i++) {
            all_percent += percentList[i];
        }

        require(
            all_percent <= 100,
            "total fund percent should be less than 100%"
        );

        fundIndex = 0;
        for (uint256 i = 0; i < addressList.length; i++) {
            fundList[fundIndex] = FundWallet(addressList[i], percentList[i]);
            fundIndex++;
        }
    }

    function withdrawDttToken(uint256 amount) public {
        // require(block.timestamp > presaleEndTime, "Presale is in progress");
        require(
            tokenBalance[msg.sender] > 0,
            "No tokens are within your presale balance."
        );
        require(
            tokenBalance[msg.sender] >= amount,
            "You are attempting to claim more tokens than are within your presale balance."
        );
        BNB20Token.transfer(msg.sender, amount);
        withdrawBalance[msg.sender] += amount;
        tokenBalance[msg.sender] -= amount;
        uncliamedSoldTokens -= amount;
    }

    function setTokenCountPerEth(uint256 _count) public onlyOwner(msg.sender) {
        TokenCountPerEth = _count;
    }

    function buyDttToken() public payable {
        require(!isPresaleEnded, "Presale is ended");
        require(block.timestamp <= presaleEndTime, "Presale period is ended");
        uint256 tokenCount = msg.value.mul(TokenCountPerEth).div(10**18);
        require(
            uncliamedSoldTokens + tokenCount <=
                BNB20Token.balanceOf(address(this)),
            "Not enough tokens remaining in presale."
        );

        if (tokenBalance[msg.sender] == 0) {
            totalParticipants++;
        }

        tokenBalance[msg.sender] += tokenCount;
        uncliamedSoldTokens += tokenCount;
        totalSoldTokens += tokenCount;
    }

    function availableTokenForPresale() public view returns (uint256) {
        return BNB20Token.balanceOf(address(this));
    }

    function balanceOf() public view returns (uint256) {
        return address(this).balance;
    }

    function getTokenDecimals() public view returns (uint256) {
        return BNB20Token.decimals();
    }

    function withdrawETH() public onlyOwner(msg.sender) {
        //onlyOwner
        require(fundIndex >= 1, "Fund Wallet should be set");
        uint256 total_balance = address(this).balance;
        for (uint256 i = 0; i < fundIndex; i++) {
            FundWallet memory fundWallet = fundList[i];
            payable(fundWallet.wallet).transfer(
                total_balance.mul(fundWallet.percent).div(100)
            );
        }
    }

    function setPresalePeriod(uint256 _presalePeriod)
        public
        onlyOwner(msg.sender)
    {
        presalePeriod = _presalePeriod.mul(1 days);
        presaleEndTime = presaleStartTime.add(presalePeriod);
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
