import Lib "../src/lib";
import T "../src/types";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";

// Test owners
let canister_owner = Principal.fromText("mxzaz-hqaaa-aaaar-qaada-cai");
let user_owner = Principal.fromText("uwxxa-dgs3m-vel7y-vpvcc-uncu3-bjxts-paa5t-6zc5v-hfv4e-hmjza-uqe");

// Test subaccounts
let test_subaccount = "\01\02\03\04\05\06\07\08\09\0a\0b\0c\0d\0e\0f\10\11\12\13\14\15\16\17\18\19\1a\1b\1c\1d\1e\1f\20" : Blob;

// Test all combinations of owners and subaccounts
// 1. Canister owner + null subaccount
let account1 : T.Account = {
    owner = canister_owner;
    subaccount = null;
};

let blob1 = Lib.account2blob(account1);
assert blob1.size() > 0;
Debug.print("✓ Canister owner + null subaccount: blob size = " # debug_show(blob1.size()));

// 2. Canister owner + 32-byte subaccount
let account2 : T.Account = {
    owner = canister_owner;
    subaccount = ?test_subaccount;
};

let blob2 = Lib.account2blob(account2);
assert blob2.size() > blob1.size();
Debug.print("✓ Canister owner + 32-byte subaccount: blob size = " # debug_show(blob2.size()));

// 3. User owner + null subaccount
let account3 : T.Account = {
    owner = user_owner;
    subaccount = null;
};

let blob3 = Lib.account2blob(account3);
assert blob3.size() > 0;
assert blob3.size() > blob1.size(); // User principal is longer than canister principal
Debug.print("✓ User owner + null subaccount: blob size = " # debug_show(blob3.size()));

// 4. User owner + 32-byte subaccount
let account4 : T.Account = {
    owner = user_owner;
    subaccount = ?test_subaccount;
};

let blob4 = Lib.account2blob(account4);
assert blob4.size() > blob3.size();
assert blob4.size() > blob2.size(); // User principal is longer than canister principal
Debug.print("✓ User owner + 32-byte subaccount: blob size = " # debug_show(blob4.size()));

// Test blob2account for all combinations
// 1. Test canister owner + null subaccount
switch (Lib.blob2account(blob1)) {
    case (?account) {
        assert Principal.equal(account.owner, canister_owner);
        assert account.subaccount == null;
        Debug.print("✓ blob2account correctly reconstructs canister owner + null subaccount");
    };
    case null {
        assert false; // Should not fail
    };
};

// 2. Test canister owner + 32-byte subaccount
switch (Lib.blob2account(blob2)) {
    case (?account) {
        assert Principal.equal(account.owner, canister_owner);
        switch (account.subaccount) {
            case (?sub) {
                assert Blob.equal(sub, test_subaccount);
                Debug.print("✓ blob2account correctly reconstructs canister owner + 32-byte subaccount");
            };
            case null {
                assert false; // Should have subaccount
            };
        };
    };
    case null {
        assert false; // Should not fail
    };
};

// 3. Test user owner + null subaccount
switch (Lib.blob2account(blob3)) {
    case (?account) {
        assert Principal.equal(account.owner, user_owner);
        assert account.subaccount == null;
        Debug.print("✓ blob2account correctly reconstructs user owner + null subaccount");
    };
    case null {
        assert false; // Should not fail
    };
};

// 4. Test user owner + 32-byte subaccount
switch (Lib.blob2account(blob4)) {
    case (?account) {
        assert Principal.equal(account.owner, user_owner);
        switch (account.subaccount) {
            case (?sub) {
                assert Blob.equal(sub, test_subaccount);
                Debug.print("✓ blob2account correctly reconstructs user owner + 32-byte subaccount");
            };
            case null {
                assert false; // Should have subaccount
            };
        };
    };
    case null {
        assert false; // Should not fail
    };
};

// Test round-trip conversion for all combinations
let test_accounts = [account1, account2, account3, account4];
let test_blobs = [blob1, blob2, blob3, blob4];
let descriptions = [
    "canister owner + null subaccount",
    "canister owner + 32-byte subaccount", 
    "user owner + null subaccount",
    "user owner + 32-byte subaccount"
];

var i = 0;
for (blob in test_blobs.vals()) {
    let original_account = test_accounts[i];
    let description = descriptions[i];
    
    switch (Lib.blob2account(blob)) {
        case (?reconstructed) {
            assert Principal.equal(reconstructed.owner, original_account.owner);
            switch (reconstructed.subaccount, original_account.subaccount) {
                case (?r_sub, ?o_sub) {
                    assert Blob.equal(r_sub, o_sub);
                    Debug.print("✓ Round-trip conversion preserves: " # description);
                };
                case (null, null) {
                    Debug.print("✓ Round-trip conversion preserves: " # description);
                };
                case _ {
                    assert false; // Subaccounts should match
                };
            };
        };
        case null {
            assert false; // Should not fail
        };
    };
    i += 1;
};

// Test edge cases
// Empty blob should return null
switch (Lib.blob2account("" : Blob)) {
    case null {
        Debug.print("✓ Empty blob correctly returns null");
    };
    case (?_) {
        assert false; // Should return null
    };
};

// Test with anonymous principal
let anon_account : T.Account = {
    owner = Principal.fromText("2vxsx-fae");
    subaccount = null;
};

let anon_blob = Lib.account2blob(anon_account);
switch (Lib.blob2account(anon_blob)) {
    case (?account) {
        assert Principal.equal(account.owner, anon_account.owner);
        Debug.print("✓ Anonymous principal handled correctly");
    };
    case null {
        assert false; // Should not fail
    };
};

// Test different subaccount patterns
let zero_subaccount = "\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00" : Blob;
let max_subaccount = "\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff\ff" : Blob;

// Test with zero subaccount
let account_zero_sub : T.Account = {
    owner = canister_owner;
    subaccount = ?zero_subaccount;
};

let blob_zero_sub = Lib.account2blob(account_zero_sub);
switch (Lib.blob2account(blob_zero_sub)) {
    case (?account) {
        assert Principal.equal(account.owner, canister_owner);
        switch (account.subaccount) {
            case (?sub) {
                assert Blob.equal(sub, zero_subaccount);
                Debug.print("✓ Zero subaccount handled correctly");
            };
            case null {
                assert false; // Should have subaccount
            };
        };
    };
    case null {
        assert false; // Should not fail
    };
};

// Test with max subaccount
let account_max_sub : T.Account = {
    owner = user_owner;
    subaccount = ?max_subaccount;
};

let blob_max_sub = Lib.account2blob(account_max_sub);
switch (Lib.blob2account(blob_max_sub)) {
    case (?account) {
        assert Principal.equal(account.owner, user_owner);
        switch (account.subaccount) {
            case (?sub) {
                assert Blob.equal(sub, max_subaccount);
                Debug.print("✓ Max subaccount handled correctly");
            };
            case null {
                assert false; // Should have subaccount
            };
        };
    };
    case null {
        assert false; // Should not fail
    };
};

Debug.print("All lib.mo tests passed! ✅");