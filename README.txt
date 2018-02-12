***********************************************************************
*
* 這是一個針對google test為原型的qml mock, 有興趣的話就繼續往下看吧
*
***********************************************************************

1. 先看product code, Logic.qml, 了解一下這個邏輯是在做甚麼
2. 再看UT\tst_Logic.qml, 裡面有舊測試方法跟新測試方法的比較
3. 如果覺得有興趣, 可以再看UT\tst_MockComponentDoc.qml, 有完整的document
4. 用QtCreator打開QMLMockComponent.pro就可執行tst_MockComponentDoc.qml的test case(會有兩個fail是要表現fail長甚麼樣子)
