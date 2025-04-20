# 第一阶段：构建环境
FROM python:3.5-slim-stretch

# 添加版本标签 (可选，根据需要保留或移除)
# LABEL version="1.0.0"
# LABEL description="Intelligent Physicist Project"
# LABEL maintainer="imdhios@gmail.com"

# 设置工作目录
WORKDIR /app

# 设置pip使用中科大源，并升级 pip, setuptools, wheel (使用 --use-pep517)
# 注意：这里已经包含了 pip, setuptools, wheel 的升级，后续的重复升级可以移除
# 使用 --no-cache-dir 减少镜像大小
RUN pip config set global.index-url https://mirrors.ustc.edu.cn/pypi/web/simple \
    && pip config set global.trusted-host mirrors.ustc.edu.cn \
    && pip config set global.timeout 300 \
    && pip config set global.retries 5 \
    && pip install --no-cache-dir --use-pep517 --upgrade pip setuptools wheel

RUN echo "deb http://archive.debian.org/debian stretch main contrib non-free" > /etc/apt/sources.list && \
echo "deb http://archive.debian.org/debian-security stretch/updates main contrib non-free" >> /etc/apt/sources.list

# --no-install-recommends 可以减少安装一些非必需的推荐包
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgfortran3 \
    libffi-dev \
    libssl-dev \ 
    git && \
    rm -rf /var/lib/apt/lists/*

# 设置环境变量
ENV PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONIOENCODING=utf8 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PIP_DEFAULT_TIMEOUT=300
    # SETUPTOOLS_USE_DISTUTILS=stdlib # 这行本来就是注释掉的

# 安装 Jupyter Notebook 和 JupyterLab 以及常用的科学计算库
# 这些库（尤其是 scipy, scikit-learn 的一些依赖如 cffi）会依赖上面安装的编译工具
RUN pip install --no-cache-dir \
    notebook \
    jupyterlab \
    numpy \
    pandas \
    matplotlib \
    scipy \
    scikit-learn

# 暴露 Jupyter Notebook 默认端口
EXPOSE 8888

# 复制项目文件到容器的工作目录
COPY . .

# 安装项目自身 (Editable mode)
# 这个步骤也会依赖编译工具，特别是如果你的项目或其依赖需要编译 C/C++/Fortran
RUN pip install --no-cache-dir --use-pep517 -e . -i https://mirrors.ustc.edu.cn/pypi/web/simple

# 如果项目安装需要在非root用户下完成，需要在这里添加用户创建和权限修改步骤
# RUN useradd -m -s /bin/bash appuser && chown -R appuser:appuser /app
# USER appuser
# 注意：如果在非root用户下安装项目，上面的一些RUN pip install... 步骤需要在切换用户后进行

# 容器启动时运行的命令
CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]