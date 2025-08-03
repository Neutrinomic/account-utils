import NTC "../src/ntc";
import T "../src/types";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Debug "mo:base/Debug";

// Test canister principals
let test_canister1 = Principal.fromText("ss2fx-dyaaa-aaaar-qacoq-cai");
let test_canister2 = Principal.fromText("mxzaz-hqaaa-aaaar-qaada-cai");

// Test canister2subaccount with refill type
let refill_subaccount = NTC.canister2subaccount(test_canister1, #refill);
assert refill_subaccount.size() == 32;
Debug.print("✓ canister2subaccount produces 32-byte subaccount for refill");

// Test canister2subaccount with call type
let call_subaccount = NTC.canister2subaccount(test_canister1, #call);
assert call_subaccount.size() == 32;
assert not Blob.equal(call_subaccount, refill_subaccount);
Debug.print("✓ canister2subaccount produces different subaccount for call type");

// Test that call subaccount starts with 1
let call_bytes = Blob.toArray(call_subaccount);
assert call_bytes[0] == 1;
Debug.print("✓ call subaccount correctly starts with 1");

// Test that refill subaccount starts with 0
let refill_bytes = Blob.toArray(refill_subaccount);
assert refill_bytes[0] == 0;
Debug.print("✓ refill subaccount correctly starts with 0");

// Test subaccount2canister with refill type
switch (NTC.subaccount2canister(refill_bytes)) {
    case (?(principal, sa_type)) {
        assert Principal.equal(principal, test_canister1);
        assert sa_type == #refill;
        Debug.print("✓ subaccount2canister correctly reconstructs refill canister");
    };
    case null {
        assert false; // Should not fail
    };
};

// Test subaccount2canister with call type
switch (NTC.subaccount2canister(call_bytes)) {
    case (?(principal, sa_type)) {
        assert Principal.equal(principal, test_canister1);
        assert sa_type == #call;
        Debug.print("✓ subaccount2canister correctly reconstructs call canister");
    };
    case null {
        assert false; // Should not fail
    };
};

// Test round-trip conversion for different canisters
let test_canisters = [
    test_canister1,
    test_canister2,
];

let test_types : [NTC.SubaccountType] = [#refill, #call];

for (canister in test_canisters.vals()) {
    for (sa_type in test_types.vals()) {
        let subaccount = NTC.canister2subaccount(canister, sa_type);
        let subaccount_bytes = Blob.toArray(subaccount);
        switch (NTC.subaccount2canister(subaccount_bytes)) {
            case (?(reconstructed_canister, reconstructed_type)) {

                assert Principal.equal(reconstructed_canister, canister);
                assert reconstructed_type == sa_type;
            };
            case null {
                assert false; // Should not fail
            };
        };
    };
};
Debug.print("✓ Round-trip conversion works for all test canisters and types");

// Test account function
let ntc_account_refill = NTC.account(test_canister1, #refill);
assert Principal.equal(ntc_account_refill.owner, Principal.fromText("7ew52-sqaaa-aaaal-qsrda-cai"));
switch (ntc_account_refill.subaccount) {
    case (?sub) {
        assert Blob.equal(sub, refill_subaccount);
        Debug.print("✓ account function creates correct refill account");
    };
    case null {
        assert false; // Should have subaccount
    };
};

let ntc_account_call = NTC.account(test_canister1, #call);
assert Principal.equal(ntc_account_call.owner, Principal.fromText("7ew52-sqaaa-aaaal-qsrda-cai"));
switch (ntc_account_call.subaccount) {
    case (?sub) {
        assert Blob.equal(sub, call_subaccount);
        Debug.print("✓ account function creates correct call account");
    };
    case null {
        assert false; // Should have subaccount
    };
};

// Test edge cases
// Invalid subaccount size
let invalid_size_subaccount = Array.freeze(Array.init<Nat8>(31, 0)); // Wrong size
switch (NTC.subaccount2canister(invalid_size_subaccount)) {
    case null {
        Debug.print("✓ Invalid size subaccount correctly returns null");
    };
    case (?_) {
        assert false; // Should return null
    };
};

// Invalid canister size in subaccount
let invalid_canister_subaccount = Array.freeze(Array.init<Nat8>(32, 0));
let invalid_bytes = Array.thaw<Nat8>(invalid_canister_subaccount);
invalid_bytes[31] := 30; // Invalid size > 20
let invalid_frozen = Array.freeze<Nat8>(invalid_bytes);

switch (NTC.subaccount2canister(invalid_frozen)) {
    case null {
        Debug.print("✓ Invalid canister size correctly returns null");
    };
    case (?_) {
        assert false; // Should return null
    };
};

// Zero size canister
let zero_size_subaccount = Array.freeze(Array.init<Nat8>(32, 0));
switch (NTC.subaccount2canister(zero_size_subaccount)) {
    case null {
        Debug.print("✓ Zero size canister correctly returns null");
    };
    case (?_) {
        assert false; // Should return null
    };
};

Debug.print("All ntc.mo tests passed! ✅"); 