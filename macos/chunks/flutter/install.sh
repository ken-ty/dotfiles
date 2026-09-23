#!/bin/bash
# flutter の後処理: asdf の flutter プラグインと、~/.tool-versions に書いてある版を入れる。
set -eu
export PATH="/opt/homebrew/bin:$PATH"
asdf plugin list 2>/dev/null | grep -qx flutter || asdf plugin add flutter
(cd "$HOME" && asdf install flutter)

# brew の openjdk を /usr/libexec/java_home (Android Studio や Gradle が JDK を探す場所) に見せる。
# brew が案内している symlink。sudo が要るので、無いときだけ聞く。
jdk_link="/Library/Java/JavaVirtualMachines/openjdk.jdk"
jdk_src="$(brew --prefix)/opt/openjdk/libexec/openjdk.jdk"
if [ -d "$jdk_src" ] && [ ! -e "$jdk_link" ]; then
    echo "openjdk を java_home に登録する (sudo)"
    sudo ln -sfn "$jdk_src" "$jdk_link"
fi
