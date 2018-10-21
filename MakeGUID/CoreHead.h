/********************************************************************
	created:	2013/01/01
	created:	1:1:2013   0:04
	filename: 	C:\GoodFrame\MemPoolTest\MemPoolTest\CoreHead.h
	file path:	C:\GoodFrame\MemPoolTest\MemPoolTest
	file base:	CoreHead
	file ext:	h
	author:		hgj
	
	purpose:	�ں˵Ľṹ���ꡢö�١�
*********************************************************************/


#ifndef CORE_HEAD_H
#define CORE_HEAD_H

//#include <memory>
// ����һЩ����
#pragma warning(disable:4995)
#pragma warning(disable:4996)
#pragma warning(disable:4251)

// ��� <windows.h>�а�����<winsock.h>ͷ�ļ��Ӷ��� #include "Winsock2.h" ���ͻ������
// һ��Ҫ���� #include <windows.h> ֮ǰ
//#define WIN32_LEAN_AND_MEAN
//#include <windows.h>

#define INVALID_CHANNEL_NO -1	// ��Ч��ͨ����
#define INVALID_MAIN_CODE  -1	// ��Ч������
#define INVALID_SUB_CODE   -1	// ��Ч�ĸ�����

#define WAIT_EXIT_TIME 60*1000	// ��Ҫ��Ϊ WaitForSingleObject �ȷ����

//--- ����ص���Ϣ��TPM �� TASK_POOL_MSG ����д -------------------------------------------------------------------
#define TPM_CORE_NORMAL	 0	// �ں��ĵ�������Ϣ
#define TPM_CORE_EXIT	10	// �ں��ĵ��˳���Ϣ

//#include "./TaskMsgResult.h"

// �ں˼��ܲ�
struct CORE_ENCRYPTION
{
	BYTE bySegment[16];	// Ԥ������ʱû��
};

// �ں���Ϣ��ͷ
struct CORE_MSG_HEAD	
{
	CORE_MSG_HEAD()
	{
		uFlag = 0xaaaaaaaaaaaaaaaa;
		bIsHeartbeat = 0;
		lChannelNo = INVALID_CHANNEL_NO;	
		dwPeerIP = 0;	
		iMainCode = INVALID_MAIN_CODE;	// ��Ч������
		iSubCode = INVALID_SUB_CODE;	// ��Ч�ĸ�����

		iTotalSize = sizeof(CORE_MSG_HEAD);
	}

	void SetTotalSize(int iSize)
	{
		iTotalSize = iSize;
	}

	int GetTotalSize()
	{
		return iTotalSize;
	}

	// ��ԭ���Ȼ��������ӳ���
	int RaiseTotalSize(int iRaiseSize)
	{
		iTotalSize += iRaiseSize;

		return iTotalSize;
	}

	ULONGLONG 		uFlag;			// ��־λ��ÿ���ֽڶ�Ӧ���� 0xaa ,��ֵӦ���� 0xaaaaaaaaaaaaaaaa  ;
    int				bIsHeartbeat;	// 0 ��ʾ����������1 ��ʾ������
	int				iTotalSize;		// ������Ϣ�ĳ��ȣ� sizeof(CORE_MSG) +  iBodyLen 
	LONGLONG		lChannelNo;		// ͨ���ţ������ר��
	unsigned int	dwPeerIP;		// �Զ�������IP
	int				iMainCode;
	int			    iSubCode;

	CORE_ENCRYPTION	encryption;
};



#endif