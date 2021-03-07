//
//  MemoryTalkInfo.swift
//  RevengeUrVoice
//
//  Created by 나윤서 on 2021/03/07.
//

import Foundation
import SQLite3

var db_TalkInfo: OpaquePointer?          // db 를 가르키는 포인터
let path_TalkInfo: String = {
      let fm = FileManager.default
      return fm.urls(for:.libraryDirectory, in:.userDomainMask).last!
               .appendingPathComponent("TalkInfo.db").path
    }()

let createTalkInfoString = """
   CREATE TABLE IF NOT EXISTS TalkInfo(
   id Int PRIMARY KEY NOT NULL,
   TalkFor CHAR(255),
   ToTalk CHAR(255));
   """

class TalkInfo {
    var talkFor: String
    var toTalk: String
    
    init(talkFor: String, toTalk: String) {
        self.talkFor = talkFor
        self.toTalk = toTalk
    }
}

class TalkInfoDB: NSObject {
    override init() {
        if sqlite3_open(path_TalkInfo, &db_TalkInfo) == SQLITE_OK {
            if sqlite3_exec(db_TalkInfo,createTalkInfoString,nil,nil,nil) == SQLITE_OK {
                return
            }
        }
        // throw error
    }
    deinit {
        sqlite3_close(db_TalkInfo)
    }
    
    static let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    func createInfoDB() {
      var createTableStatement: OpaquePointer?
      if sqlite3_prepare_v2(db_TalkInfo, createTalkInfoString, -1, &createTableStatement, nil) == SQLITE_OK {
        if sqlite3_step(createTableStatement) == SQLITE_DONE {
          print("\nTalkInfo Table created.")
        } else {
          print("\nTalkInfo Table is not created.")
        }
      } else {
        print("\nCREATE TalkInfo statement is not prepared.")
      }
      sqlite3_finalize(createTableStatement)
    }
    
    static func insertTalkInfo(talkFor: String, toTalk: String) -> Int {
        let insertStatementString = "INSERT INTO TalkInfo (id,TalkFor, ToTalk) VALUES (?,?,?);"
        var statement: OpaquePointer?
        
        if sqlite3_prepare(db_TalkInfo, insertStatementString, -1, &statement, nil) == SQLITE_OK {       // 쿼리 생성
            sqlite3_bind_int(statement, 1, Int32(0))            // id, Primary Key
            sqlite3_bind_text(statement, 2, talkFor, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, toTalk, -1, SQLITE_TRANSIENT)
            
            if sqlite3_step(statement) == SQLITE_DONE {         // 쿼리 실행
//                print("DB Insert Row Success\n")
            } else {
                print("TalkInfo DB Insert Row Failed\n")
            }
        } else {
            print("Talk Info Insert Statement is not prepared\n")
        }
        
        sqlite3_finalize(statement)         // 쿼리 반환
        return Int(sqlite3_last_insert_rowid(db_TalkInfo))
    }
    
    static func updateTalkInfo(talkFor: String, toTalk: String) {
        let updateStatementString = "UPDATE TalkInfo SET TalkFor = '\(talkFor)', ToTalk = '\(toTalk)' WHERE Id = \(0);"
        var statement: OpaquePointer?
        
        if sqlite3_prepare(db_TalkInfo, updateStatementString, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
//                print("DB Update Row Success\n")
            } else {
                print("TalkInfo Update Row Failed\n")
            }
        } else {
            print("Update TalkInfo Statement is not prepared\n")
        }
        
        sqlite3_finalize(statement)
    }
    
    static func readTalkInfo() -> TalkInfo? {
        let readWorkedItemStatementString = "SELECT * FROM TalkInfo WHERE Id = \(0);"
        var statement: OpaquePointer?
        var item: TalkInfo? = nil
        if sqlite3_prepare(db_TalkInfo, readWorkedItemStatementString, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                guard let talkFor = sqlite3_column_text(statement, 1) else {
                    return nil
                }
                guard let toTalk = sqlite3_column_text(statement, 2) else {
                    return nil
                }
                
                let talkInfo: TalkInfo = TalkInfo(talkFor: String(cString: talkFor), toTalk: String(cString: toTalk))
                item = talkInfo
            }
        } else {
            print("Query is not prepared for ReadTalkInfo\n")
        }
        
        sqlite3_finalize(statement)
        return item
    }
    
    static func deleteInfoAll() {
        let deleteAllStatementString = "DELETE FROM TalkInfo"
        var statement: OpaquePointer?
        
        if sqlite3_prepare(db_TalkInfo, deleteAllStatementString, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
//                print("DB Delete All Success\n")
            } else {
                print("DB TalkInfo DeleteInfoAll Failed\n")
            }
        } else {
            print("Query is not prepared for DeleteAll TalkInfo\n")
        }
        
        sqlite3_finalize(statement)
    }

    static func deleteTalkInfoTable() {
        let deleteStatementString = "DROP TABLE TalkInfo;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare(db_TalkInfo, deleteStatementString, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
//                print("Delete Row Success\n")
            } else {
                print("Delete TalkInfo Table Failed'n")
            }
        } else {
            print("Delete TalkInfo Table Statement in not prepared\n")
        }
        sqlite3_finalize(statement)
    }
    

}
