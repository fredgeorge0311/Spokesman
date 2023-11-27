//
//  SVZArchiveUpdateCallback.h
//  SevenZip
//
//  Created by Tamas Lustyik on 2015. 11. 19..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

#ifndef SVZArchiveUpdateCallback_h
#define SVZArchiveUpdateCallback_h

#include <functional>

#include "CPP/myWindows/StdAfx.h"
#include "CPP/7zip/Archive/IArchive.h"
#include "CPP/7zip/IPassword.h"
#include "CPP/Common/MyCom.h"
#include "CPP/Common/MyString.h"
#include "CPP/Common/MyWindows.h"

namespace SVZ {

    struct ArchiveItem {
        static const Int32 kNewItemIndex = -1;
        
        Int32 currentIndex;
        
        Int32 id;
        
        UInt64 size;
        FILETIME cTime;
        FILETIME aTime;
        FILETIME mTime;
        UString name;
        UInt32 attrib;
        bool isDir;
    };
    
    class ArchiveUpdateCallback: public IArchiveUpdateCallback2,
                                 public ICryptoGetTextPassword2,
                                 public CMyUnknownImp {
    public:
        MY_UNKNOWN_IMP2(IArchiveUpdateCallback2, ICryptoGetTextPassword2)
        
        // IProgress
        STDMETHOD(SetTotal)(UInt64 size);
        STDMETHOD(SetCompleted)(const UInt64 *completeValue);
        
        // IUpdateCallback2
        STDMETHOD(GetUpdateItemInfo)(UInt32 index,
                                     Int32 *newData, Int32 *newProperties, UInt32 *indexInArchive);
        STDMETHOD(GetProperty)(UInt32 index, PROPID propID, PROPVARIANT *value);
        STDMETHOD(GetStream)(UInt32 index, ISequentialInStream **inStream);
        STDMETHOD(SetOperationResult)(Int32 operationResult);
        STDMETHOD(GetVolumeSize)(UInt32 index, UInt64 *size);
        STDMETHOD(GetVolumeStream)(UInt32 index, ISequentialOutStream **volumeStream);
        
        STDMETHOD(CryptoGetTextPassword2)(Int32 *passwordIsDefined, BSTR *password);
        
    public:
        CRecordVector<UInt64> volumesSizes;
        UString volName;
        UString volExt;
        FString dirPrefix;
        
        bool passwordIsDefined;
        UString password;
        
    private:
        std::function<CMyComPtr<ISequentialInStream>(Int32)> _streamProvider;
        bool _needBeClosed;
        const CObjectVector<ArchiveItem> *_archiveItems;
        FStringVector _failedFiles;
        CRecordVector<HRESULT> _failedCodes;

    public:
        ArchiveUpdateCallback(): passwordIsDefined(false), _archiveItems(nullptr) {}
        
        ~ArchiveUpdateCallback() { Finalize(); }
        HRESULT Finalize();
        
        void Init(const CObjectVector<ArchiveItem> *archiveItems,
                  std::function<CMyComPtr<ISequentialInStream>(Int32)> streamProvider) {
            _archiveItems = archiveItems;
            _streamProvider = streamProvider;
            _needBeClosed = false;
            _failedFiles.Clear();
            _failedCodes.Clear();
        }
        
        const FStringVector& FailedFiles() const { return _failedFiles; }
        const CRecordVector<HRESULT>& FailedCodes() const { return _failedCodes; }
    };

}

#endif /* SVZArchiveUpdateCallback_h */
