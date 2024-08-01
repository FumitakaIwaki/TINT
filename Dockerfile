# ベース
ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE}
# ユーザ設定 ホストマシンと合わせる必要あり
ARG user_name=ubuntu
ARG user_id=1000
ARG group_name=ubuntu
ARG group_id=1000
# git設定
# ARG git_username=<username>
# ARG git_email=<username>


# タイムゾーンの設定
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
# aptのアップデート
RUN apt-get -y update --fix-missing && apt-get -y upgrade
# 必要なツールのインストール
RUN apt-get -y install sudo wget bzip2 git vim cmake jupyter

# ユーザの作成
RUN groupadd -g ${group_id} ${group_name}
RUN useradd -u ${user_id} -g ${group_id} -d /home/${user_name} \
    --create-home --shell /bin/bash ${user_name}
RUN echo "${user_name} ALL=(ALL) NOPASSWD:ALL \n" >> /etc/sudoers
RUN echo "Defaults env_keep += \"PATH\" \n" >> /etc/sudoers
RUN chown -R ${user_name}:${group_name} /home/${user_name}

# ユーザ設定
ENV HOME /home/${user_name}
ENV LANG en_US.UTF-8

USER ${user_name}

# gitの設定
RUN git config --global user.name ${git_username}
RUN git config --global user.email ${git_email}

# working dirの設定
WORKDIR /work
ENV LC_ALL C.UTF-8 \
    LANG C.UTF-8

# プログラムのコピー
COPY tint_prj Readme.md gitignore LICENSE  ./

# juliaのインストール
ARG JULIA_VERSION="1.10.4"
# URLは https://julialang.org/downloads/ から探して選択
RUN wget --quiet https://julialang-s3.julialang.org/bin/linux/x64/1.10/julia-1.10.4-linux-x86_64.tar.gz \
    -O $HOME/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    cd $HOME && \
    tar -xvzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz
ENV PATH $HOME/julia-${JULIA_VERSION}/bin:$PATH

RUN julia -e "using Pkg; Pkg.activate('tint_prj'); Pkg.instantiate()"

CMD ["/bin/bash"]