music cutter
===========

複数のmp3ファイルを一括で、一定の長さに切り、フェードアウトさせます。

## Description
複数のmp3ファイルを一括で、一定の長さに切り、フェードアウトさせます。
”ここにmp3ファイルをドロップしてください”というところに、
複数のmp3ファイルをドロップしてください。
成功すると”出力されるCのイメージ"というところに、
ファイル名等表示されます。
複数回ドロップできます。
送信ボタンを押すと、編集された曲(mp3)がzipファイルとしてダウンロードされます。


## Requirement

see Gemfile

public/js-lib
配下に,
jquery.js,dropzone.jsをおいてください。

dropzone.js
Version 3.12.0 026fba1d727355d5183e42c65ecf7ef9

jQuery v1.10.1
にて動作確認をしています。

これらは別途ダウンロードしてください。


## Usage

- 起動

`$  ruby musicutter.rb`
  として、起動します。

- http://127.0.0.1:4567/ にアクセスしてください。


## Install
  展開しそのまま実行してください。

## etc
  利用の際は感想等メールにてご連絡を頂けると励みになります。

## Licence
  This software is released under the MIT License, 

## Author
  Hasegawa.tadamitsu@gmail.com

