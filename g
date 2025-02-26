private function saveFile($contents): void {
    $filename = $this->getFilePath();
    $folder = $this->f3->get('upload_folder') . '/' . $this->getSubfolder($this->extension);
    if (!file_exists($folder)) {
        mkdir($folder, 0777, true); // Set directory permissions to 777
        chmod($folder, 0777); // Ensure permissions are set (in case of NFS issues)
    }
    file_put_contents($filename, $contents);
    chmod($filename, 0777); // Set file permissions to 777

    // Update the database
    $date = $this->now();
    if (!$this->file->valid()) {
        // This is a new record
        $this->file->filename = $this->filename;
        $this->file->filetype = strtolower($this->extension);
        $this->file->created = $date;
    }
    $this->file->updated = $date;
    $this->file->hash = $this->hash;
    $this->file->bytes = filesize($filename);

    $this->file->save();
}
