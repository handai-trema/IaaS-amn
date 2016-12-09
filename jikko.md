コードは bin/sliceに追加


#コマンドの実行
スライスの統合  
```
ensyuu2@ensyuu2-VirtualBox:~/sliceable-switch-team-w$ ./bin/slice list
slice2
  0x6:1
    44:44:44:44:44:44
slice5
  0x4:1
    22:22:22:22:22:22
  0x1:1
    11:11:11:11:11:11
ensyuu2@ensyuu2-VirtualBox:~/sliceable-switch-team-w$ ./bin/slice merge slice4 slice2 slice5
ensyuu2@ensyuu2-VirtualBox:~/sliceable-switch-team-w$ ./bin/slice list
slice4
  0x6:1
    44:44:44:44:44:44
  0x4:1
    22:22:22:22:22:22
  0x1:1
    11:11:11:11:11:11

```


スライスの分割 (コマンド入力後、コンソール入力が求められる)  
```
ensyuu2@ensyuu2-VirtualBox:~/sliceable-switch-team-w$ ./bin/slice list
slice5
  0x4:1
    22:22:22:22:22:22
  0x6:1
    44:44:44:44:44:44
  0x1:1
    11:11:11:11:11:11
ensyuu2@ensyuu2-VirtualBox:~/sliceable-switch-team-w$ ./bin/slice split slice5
Input slice name= 
slice1
Input host name= 
22:22:22:22:22:22
nagatomi
Input host name= (MACアドレスを入力)
end
Input slice name= 
slice2
Input host name= 
44:44:44:44:44:44
nagatomi
Input host name= 
end
Input slice name= 
slice3
Input host name= 
11:11:11:11:11:11
nagatomi
Input host name= 
end(endとしたら、その入力を終了するようになっている。)
Input slice name= 
end
Input host name= 
end
ensyuu2@ensyuu2-VirtualBox:~/sliceable-switch-team-w$ ./bin/slice list
slice1
  0x4:1
    22:22:22:22:22:22
slice2
  0x6:1
    44:44:44:44:44:44
slice3
  0x1:1
    11:11:11:11:11:11

```



#まだ出来てない?追加できたらいいなと思ってるとこ
* n個のスライスの統合(2個しかできない)
* パス情報の保持（すべきかどうかは疑問）
* MACでなく、hostネームを入力 (すべきかどうかは疑問)
