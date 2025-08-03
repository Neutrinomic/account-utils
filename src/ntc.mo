import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Iter "mo:core/Iter";
import Nat "mo:base/Nat";
import T "types";

module {

    public func canister2subaccount(canister_id : Principal, sa_type : SubaccountType) : Blob {
        let can = Blob.toArray(Principal.toBlob(canister_id));
        let size = can.size();
        let pad_start = 32 - size - 1:Nat;
        var sa = Iter.toArray(Iter.flatten<Nat8>([
            Iter.repeat<Nat8>(0, pad_start),
            Iter.fromArray(can),
            Iter.singleton(Nat8.fromNat(size))
            ].vals()));

        if (sa_type == #call) {
            let va = Array.thaw<Nat8>(sa);
            va[0] := 1;
            sa := Array.freeze<Nat8>(va);
        };

        Blob.fromArray(sa);
    };

    public type SubaccountType = { #call; #refill };

    public func subaccount2canister(subaccount : [Nat8]) : ?(Principal, SubaccountType) {
        if (subaccount.size() != 32) return null;
        let sa_type : SubaccountType = if (subaccount[0] == 1) #call else #refill;
        let size = Nat8.toNat(subaccount[31]);
        if (size == 0 or size > 20) return null;
        let p = Principal.fromBlob(Blob.fromArray(Iter.toArray(Array.slice(subaccount, 31 - size:Nat, 31))));
        if (Principal.isAnonymous(p)) return null;
        if (Principal.toText(p).size() != 27) return null; // Is Canister
        ?(p, sa_type)
    };

    public func account(canister_id : Principal, stype: SubaccountType) : T.Account {
        {
            owner = Principal.fromText("7ew52-sqaaa-aaaal-qsrda-cai");
            subaccount = ?canister2subaccount(canister_id, stype);
        };
    };

}