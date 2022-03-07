pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SpaceMarvelBox is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct PaymentOption {
        address token;
        uint256 price;
    }

    struct PaymentInfo {
        address token;
        uint256 price;
        uint256 receivedAmount;
    }

    struct Box {
        // maxmimum number of NFT(s) user can buy
        uint32 personalLimit;
        uint32 startTime;
        uint32 endTime;
        address creator;
        uint256 maxRandom;
        bool canceled;
        string name;
        PaymentInfo[] payment;
        uint256[] idList;
        uint8[] rates;
        mapping(address => uint256[]) purchasedNft;
        // total number of NFT(s)
        uint256 total;
    }

    event CreationBox(
        address indexed creator,
        address indexed nft,
        string name,
        uint256[] idList,
        uint32 startTime,
        uint32 endTime
    );

    event BuyBox(
        address indexed nft,
        address indexed user,
        uint256[] nftUnlock
    );

    event CancelBox(address indexed nft, address indexed creator, uint256 time);

    event ClaimPayment(
        address indexed creator,
        address indexed nft,
        address token,
        uint256 amount,
        uint256 timestamp
    );

    mapping(address => Box) private boxs;
    mapping(address => bool) public admin;
    mapping(address => bool) public whitelist;

    constructor() {
        admin[_msgSender()] = true;
        whitelist[_msgSender()] = true;
    }

    function createBox(
        address _nft,
        string memory _name,
        PaymentOption[] memory _payment,
        uint32 _personalLimit,
        uint32 _startTime,
        uint32 _endTime,
        uint256[] memory _idList,
        uint8[] memory _rates
    ) external {
        require(
            whitelist[_msgSender()] || admin[_msgSender()],
            "Error: not whitelisted"
        );

        require(_endTime > block.timestamp, "Error: invalid end time");
        require(boxs[_nft].creator == address(0), "Error: box created alrady");

        require(
            IERC721(_nft).isApprovedForAll(_msgSender(), address(this)),
            "Error: not ApprovedForAll"
        );
        require(_payment.length > 0, "Error: invalid payment");

        // require(_idList.length > 0, "Error: empty nft list");
        require(_checkOwnership(_idList, _nft), "Error: not owner");
        require(_checkRate(_rates), "Error: rate invalid");

        Box storage box = boxs[_nft];
        for (uint256 i = 0; i < _payment.length; i++) {
            if (_payment[i].token != address(0)) {
                require(
                    IERC20(_payment[i].token).totalSupply() > 0,
                    "Error: Not a valid ERC20 token address"
                );
            }
            PaymentInfo memory paymentInfo = PaymentInfo(
                _payment[i].token,
                _payment[i].price,
                0
            );
            box.payment.push(paymentInfo);
        }

        box.creator = _msgSender();
        box.name = _name;
        box.personalLimit = _personalLimit;
        box.startTime = _startTime;
        box.endTime = _endTime;
        box.maxRandom = _rates.length - 1;
        box.idList = _idList;
        box.rates = _rates;

        // uint8 totalRate = 0;
        // box.rates.push(totalRate);
        // for (uint8 i = 0; i < _rates.length; i++) {
        //     totalRate += _rates[i];
        //     box.rates.push(totalRate);
        // }

        box.total = _idList.length;

        emit CreationBox(
            _msgSender(),
            _nft,
            _name,
            _idList,
            _startTime,
            _endTime
        );
    }

    // Add more NFT for sale
    function addNftIntoBox(address _nft, uint256[] calldata _idList) external {
        Box storage box = boxs[_nft];
        require(box.creator == _msgSender(), "Error: not box owner");
        address creator = box.creator;

        for (uint256 i = 0; i < _idList.length; i++) {
            address nftOwner = IERC721(_nft).ownerOf(_idList[i]);
            require(creator == nftOwner, "Error: not nft owner");
            box.idList.push(_idList[i]);
        }
        box.total += _idList.length;
    }

    // cancel sale
    function cancelBox(address _nft) external {
        Box storage box = boxs[_nft];
        require(box.creator == _msgSender(), "Error: not box owner");
        require(block.timestamp <= box.startTime, "Error: sale started");
        require(!(box.canceled), "Error: sale canceled already");
        box.canceled = true;
        emit CancelBox(_nft, _msgSender(), block.timestamp);
    }

    function updateEndTime(address _nft, uint32 _endTime) external {
        Box storage box = boxs[_nft];
        require(box.creator == _msgSender(), "Error: not box owner");
        require(_endTime > block.timestamp, "Error: invalid end time");
        require(!(box.canceled), "Error: sale canceled already");
        box.endTime = _endTime;
    }

    function getRandom() public view returns (uint256 unlock) {
        unlock = _random(100);
        uint8[7] memory rates = [0, 10, 50, 90, 97, 99, 100];
        for (uint8 i = 0; i < 6; i++) {
            if (unlock >= rates[i] && unlock <= rates[i + 1]) {
                unlock = i + 1;
                break;
            }
        }
        return unlock;
    }

    function buyBox(address _nft, uint8 _paymentIndex) external payable {
        require(tx.origin == _msgSender(), "Error: no contracts");
        Box storage box = boxs[_nft];
        require(block.timestamp >= box.startTime, "Error: not started");
        require(box.endTime > block.timestamp, "Error: expired");
        require(
            _paymentIndex < box.payment.length,
            "Error: invalid payment token"
        );
        require(
            (box.purchasedNft[_msgSender()].length + 1) <= box.personalLimit,
            "Error: exceeds personal limit"
        );
        require(!(box.canceled), "Error: sale canceled");
        require(box.idList.length > 0, "Error: sale sell all");

        address creator = box.creator;
        uint256 total = box.idList.length;

        require(total > 0, "Error: no NFT left");

        //generate number nft unlock
        /* [10, 40, 40, 7, 2, 1] =>[0, 10, 50, 90, 97, 99, 100]

        */
        uint256 unlock = _random(100);
        for (uint8 i = 0; i < box.maxRandom; i++) {
            if (unlock >= box.rates[i] && unlock <= box.rates[i + 1]) {
                unlock = i + 1;
                break;
            }
        }
        if (unlock > total) unlock = total;

        uint256 rand = _random(0);

        uint256[] memory nftUnlock = new uint256[](unlock);

        // pick NFT(s) from nft-id list
        for (uint256 i = 0; i < unlock; i++) {
            uint256 nftIndex = rand % total;
            uint256 nftId = box.idList[nftIndex];

            // transfer NFT
            IERC721(_nft).safeTransferFrom(creator, _msgSender(), nftId);
            box.purchasedNft[_msgSender()].push(nftId);

            // remove this NFT id from the list
            _removeNftId(box, nftIndex);
            rand = uint256(keccak256(abi.encodePacked(rand, i)));
            total--;
            nftUnlock[i] = nftId;
        }

        uint256 totalPayment = box.payment[_paymentIndex].price;
        address token = box.payment[_paymentIndex].token;
        if (token == address(0)) {
            require(msg.value >= totalPayment, "Error: not enough AVAL");
            uint256 refund = msg.value.sub(totalPayment);
            if (refund > 0) {
                payable(_msgSender()).transfer(refund);
            }
        } else {
            IERC20(token).safeTransferFrom(
                _msgSender(),
                address(this),
                totalPayment
            );
        }
        box.payment[_paymentIndex].receivedAmount += totalPayment;

        emit BuyBox(_nft, _msgSender(), nftUnlock);
    }

    function claimPayment(address[] calldata _nfts) external {
        for (uint256 i = 0; i < _nfts.length; i++) {
            Box storage box = boxs[_nfts[i]];
            require(box.creator == _msgSender(), "not owner");
            uint256 total = box.idList.length;

            require(
                box.endTime <= block.timestamp || total == 0,
                "Error: not expired/sold-out"
            );

            for (uint256 j = 0; j < box.payment.length; j++) {
                address token = box.payment[j].token;
                uint256 amount = box.payment[j].receivedAmount;
                if (amount == 0) {
                    continue;
                }
                box.payment[j].receivedAmount = 0;
                if (token == address(0)) {
                    address payable addr = payable(_msgSender());
                    addr.transfer(amount);
                } else {
                    IERC20(token).safeTransfer(_msgSender(), amount);
                }
                emit ClaimPayment(
                    _msgSender(),
                    _nfts[i],
                    token,
                    amount,
                    block.timestamp
                );
            }
        }
    }

    function getBoxInfo(address _nft)
        external
        view
        returns (
            address creator,
            string memory name,
            uint32 personalLimit,
            uint256 startTime,
            uint256 endTime,
            uint256 maxRandom,
            uint256[] memory idList,
            uint8[] memory rates
        )
    {
        Box storage box = boxs[_nft];
        creator = box.creator;
        name = box.name;
        personalLimit = box.personalLimit;
        startTime = box.startTime;
        endTime = box.endTime;
        maxRandom = box.maxRandom;
        idList = box.idList;
        rates = box.rates;
    }

    function getBoxStatus(address _nft)
        external
        view
        returns (
            PaymentInfo[] memory payment,
            bool started,
            bool expired,
            bool canceled,
            uint256 remaining,
            uint256 total
        )
    {
        Box storage box = boxs[_nft];
        payment = box.payment;
        started = block.timestamp >= box.startTime;
        expired = block.timestamp > box.endTime;
        canceled = box.canceled;

        remaining = box.idList.length;

        total = box.total;
    }

    function getPurchasedNft(address _nft, address _user)
        external
        view
        returns (uint256[] memory idList)
    {
        Box storage box = boxs[_nft];
        idList = box.purchasedNft[_user];
    }

    function addAdmin(address[] memory addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            admin[addrs[i]] = true;
        }
    }

    function removeAdmin(address[] memory addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            admin[addrs[i]] = false;
        }
    }

    function addWhitelist(address[] memory addrs) external {
        require(
            admin[_msgSender()] || _msgSender() == owner(),
            "Error: not admin"
        );
        for (uint256 i = 0; i < addrs.length; i++) {
            whitelist[addrs[i]] = true;
        }
    }

    function removeWhitelist(address[] memory addrs) external {
        require(
            admin[_msgSender()] || _msgSender() == owner(),
            "Error: not admin"
        );
        for (uint256 i = 0; i < addrs.length; i++) {
            whitelist[addrs[i]] = false;
        }
    }

    function _random(uint256 _threshold) public view returns (uint256) {
        uint256 blocknumber = block.number;
        uint256 randomGap = uint256(
            keccak256(
                abi.encodePacked(blockhash(blocknumber - 1), _msgSender())
            )
        ) % 255;

        uint256 randomBlock = blocknumber - 1 - randomGap;

        bytes32 sha = keccak256(
            abi.encodePacked(
                blockhash(randomBlock),
                _msgSender(),
                block.coinbase,
                block.difficulty
            )
        );
        if (_threshold != 0) return (uint256(sha) % _threshold) + 1;
        else return (uint256(sha));
    }

    function _checkOwnership(uint256[] memory _idList, address _nft)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _idList.length; i++) {
            address nftOwner = IERC721(_nft).ownerOf(_idList[i]);
            if (nftOwner != _msgSender()) {
                return false;
            }
        }
        return true;
    }

    function _removeNftId(Box storage _box, uint256 _index) private {
        require(_box.idList.length > _index, "invalid index");
        uint256 lastIndex = _box.idList.length - 1;
        // When we delete the last ID, the swap operation is unnecessary
        if (_index != lastIndex) {
            uint256 lastNftId = _box.idList[lastIndex];
            // Move the last token to the slot of the to-delete token
            _box.idList[_index] = lastNftId;
        }
        _box.idList.pop();
    }

    function _checkRate(uint8[] memory _rates) internal pure returns (bool) {
        if (
            _rates.length == 0 ||
            _rates[0] != 0 ||
            _rates[_rates.length - 1] != 100
        ) return false;

        for (uint8 i = 0; i < _rates.length - 1; i++) {
            if (_rates[i] >= _rates[i + 1]) return false;
        }

        return true;
    }
}
