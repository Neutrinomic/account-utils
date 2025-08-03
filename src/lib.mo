import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Iter "mo:core/Iter";
import T "types";
import Option "mo:base/Option";

module {
    let empty_blob = "":Blob;

    /// Useful for passing accounts as memo or storing in a map
    public func account2blob(account : T.Account) : Blob {
        let owner = Blob.toArray(Principal.toBlob(account.owner));
        let owner_size = owner.size();
        let sabytes = Blob.toArray(Option.get(account.subaccount, empty_blob));
       
        var res = Iter.toArray(Iter.flatten<Nat8>([
            Iter.singleton(Nat8.fromNat(owner_size)),
            Iter.fromArray(owner),
            Iter.fromArray(sabytes)
            ].vals()));

        Blob.fromArray(res);
    };

    public func blob2account(blob : Blob) : ?T.Account {
        let arr = Blob.toArray(blob);
        if (arr.size() < 1) return null;
        let owner_size = Nat8.toNat(arr[0]);
        if (owner_size < 1 or owner_size > 29) return null;
        let owner_bytes = Iter.toArray(Array.slice(arr, 1, 1 + owner_size));
        let owner = Principal.fromBlob(Blob.fromArray(owner_bytes));
        let subaccount :?Blob = if (arr.size() > 1 + owner_size) ?Blob.fromArray(Iter.toArray(Array.slice(arr, 1 + owner_size, arr.size()))) else null;
        ?{
            owner;
            subaccount;
        }
    };



}